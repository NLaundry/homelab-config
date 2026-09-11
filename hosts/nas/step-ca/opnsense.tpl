{
{{- $name := "opnsense.ny.laundrylab.internal" -}}
{{- if ne (len .SANs) 1 -}}
  {{ fail "exactly one SAN required" }}
{{- end -}}
{{- $san := index .SANs 0 -}}
{{- if or (ne $san.Type "dns") (ne $san.Value $name) -}}
  {{ fail "unapproved SAN" }}
{{- end -}}
{{- $cn := .Insecure.CR.Subject.CommonName -}}
{{- if and (ne $cn "") (ne $cn $name) -}}
  {{ fail "unapproved common name" }}
{{- end -}}
"subject": {"commonName": {{ toJson $name }}},
"sans": [{"type": "dns", "value": {{ toJson $name }}}],
"keyUsage": ["digitalSignature"],
"extKeyUsage": ["serverAuth"]
}
