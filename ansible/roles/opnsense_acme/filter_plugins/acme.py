"""Compare the selected existing native ACME objects without returning their keys."""
import hashlib
from uuid import UUID

from ansible.errors import AnsibleFilterError


def require(condition, message):
    if not condition:
        raise AnsibleFilterError(message)


def value(field):
    if isinstance(field, dict):
        require(all(isinstance(row, dict) and 'selected' in row for row in field.values()),
                'Unsupported ACME option field')
        return ','.join(str(key) for key, row in field.items()
                        if str(row['selected']) == '1')
    if isinstance(field, list):
        require(all(isinstance(item, str) for item in field), 'Unsupported ACME list field')
        return ','.join(field)
    if isinstance(field, bool):
        return '1' if field else '0'
    return '' if field is None else str(field)


def rows(model, section, item):
    result = model[section][item]
    require(isinstance(result, dict), 'Missing native ACME object inventory')
    for identity, row in result.items():
        require(str(UUID(identity)) == identity and isinstance(row, dict),
                'Invalid native ACME object identity')
    return result


def unique(objects, field, expected):
    matches = [(identity, row) for identity, row in objects.items()
               if row.get(field) == expected]
    require(len(matches) == 1, 'Expected one existing compatible ACME object; no creation is allowed')
    return matches[0]


def patch(current, desired):
    return {key: str(wanted) for key, wanted in desired.items()
            if value(current.get(key)) != str(wanted)}


def acme_plan(acme_response, cron_response, desired):
    stage = 'ACME inventory'
    try:
        model = acme_response['acmeclient']
        accounts = rows(model, 'accounts', 'account')
        validations = rows(model, 'validations', 'validation')
        actions = rows(model, 'actions', 'action')
        certificates = rows(model, 'certificates', 'certificate')
        stage = 'Cron inventory'
        jobs = rows(cron_response['job'], 'jobs', 'job')
        stage = 'object adoption'
        account_id, account = unique(accounts, 'name', desired['account_name'])
        validation_id, validation = unique(validations, 'name', desired['challenge_name'])
        action_id, action = unique(actions, 'name', desired['automation_name'])
        certificate_id, certificate = unique(certificates, 'description', desired['certificate_description'])
        require(value(account.get('ca')) == 'custom'
                and value(account.get('custom_ca')) == desired['directory'],
                'ACME issuer differs; deliberate migration is required')
        require(value(account.get('statusCode')) == '200' and bool(account.get('key')),
                'Existing ACME registration is required; adoption will not register an account')
        require(certificate.get('name') == desired['hostname']
                and value(certificate.get('altNames')) == ''
                and value(certificate.get('account')) == account_id
                and value(certificate.get('validationMethod')) == validation_id
                and bool(certificate.get('certRefId')),
                'Existing issued certificate name or relationships differ')
        require(value(certificate.get('restartActions')) in ('', action_id),
                'Unapproved certificate automation association')

        stage = 'Cron adoption'
        compatible = [(identity, row) for identity, row in jobs.items()
                      if row.get('origin') == 'AcmeClient']
        require(len(compatible) == 1, 'Expected one plugin-owned ACME cron job; no creation is allowed')
        job_id, job = compatible[0]
        require(value(job.get('command')) == 'acmeclient cron-auto-renew'
                and value(job.get('parameters')) == '',
                'Unapproved native renewal command or parameters')
        settings = model['settings']
        link = value(settings.get('UpdateCron'))
        require(not link or link == job_id or link not in jobs,
                'ACME cron link points to another existing job')

        stage = 'field comparison'
        operations = []
        for controller, object_key, identity, current, wanted in [
            ('accounts', 'account', account_id, account, {'enabled': '1'}),
            ('validations', 'validation', validation_id, validation, {
                'enabled': '1', 'method': 'http01', 'http_service': 'opnsense',
                'http_opn_autodiscovery': '0', 'http_opn_interface': '',
                'http_opn_ipaddresses': desired['challenge_address'],
            }),
            ('actions', 'action', action_id, action, {
                'enabled': '1', 'type': 'configd_restart_gui',
            }),
            ('certificates', 'certificate', certificate_id, certificate, {
                'enabled': '1', 'autoRenewal': '1',
                'renewInterval': str(desired['renew_interval']), 'restartActions': action_id,
            }),
        ]:
            change = patch(current, wanted)
            if change:
                operations.append({'url': f'acmeclient/{controller}/update/{identity}',
                                   'data': {object_key: change}})

        settings_patch = patch(settings, {'enabled': '1', 'autoRenewal': '1', 'UpdateCron': job_id})
        if settings_patch:
            operations.append({'url': 'acmeclient/settings/set',
                               'data': {'acmeclient': {'settings': settings_patch}}})
        schedule_patch = patch(job, desired['schedule'])
        if schedule_patch:
            # Plugin-owned cron rejects changed commands and parameters.
            schedule_patch.update(command=value(job['command']), parameters=value(job.get('parameters')))
        return {
            'operations': operations,
            'schedule': schedule_patch,
            'job_id': job_id,
            'identity': {
                'account': account_id, 'validation': validation_id,
                'action': action_id, 'certificate': certificate_id,
                'cert_ref': certificate['certRefId'],
                'account_key_sha256': hashlib.sha256(account['key'].encode()).hexdigest(),
            },
        }
    except AnsibleFilterError:
        raise
    except (KeyError, TypeError, ValueError, AttributeError):
        raise AnsibleFilterError(f'Unsupported native model at {stage}; no changes planned') from None


class FilterModule:
    def filters(self):
        return {'opnsense_acme_plan': acme_plan}
