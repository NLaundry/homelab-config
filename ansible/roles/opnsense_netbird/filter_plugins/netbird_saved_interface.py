"""Reduce private OPNsense XML to one fail-closed interface validation boolean."""
import re
import xml.etree.ElementTree as ET


class _NoDTD(ET.TreeBuilder):
    def doctype(self, name, pubid, system):
        # Do not expand entities or fetch anything referenced by the document.
        raise ValueError("DTD not allowed")


def _one(parent, tag):
    nodes = parent.findall(tag)
    if len(nodes) != 1 or nodes[0].attrib:
        raise ValueError("Missing or ambiguous field")
    return nodes[0]


def _text(parent, tag):
    node = _one(parent, tag)
    if len(node):
        raise ValueError("Non-scalar field")
    return node.text or ""


def netbird_saved_interface_enabled(content, interface):
    """Inspect only interfaces/optN identity/flags; never return XML or errors.

    Legacy flags may be empty presence elements or the saved value '1'. Missing,
    explicit false, or unfamiliar representations fail closed, never default on.
    The caller independently requires the assignment API's NetBird/locked/wt0
    identity, so this exact saved identity must agree with that API observation.
    """
    try:
        if not isinstance(content, str) or not isinstance(interface, str):
            return False
        if not re.fullmatch(r"opt[0-9]+", interface):
            return False
        root = ET.fromstring(content, parser=ET.XMLParser(target=_NoDTD()))
        if root.tag != "opnsense" or root.attrib:
            return False
        interfaces = _one(root, "interfaces")
        assigned = _one(interfaces, interface)
        if _text(assigned, "if") != "wt0" or _text(assigned, "descr") != "NetBird":
            return False
        if any(_text(assigned, flag) not in ("", "1") for flag in ("enable", "lock")):
            return False
        # Refuse a second saved owner of this device or assignment name.
        for sibling in interfaces:
            if sibling is not assigned and any(
                node.text == expected
                for tag, expected in (("if", "wt0"), ("descr", "NetBird"))
                for node in sibling.findall(tag)
            ):
                return False
        return True
    except Exception:
        # Even parser exception text can contain private XML. Never propagate it.
        return False


class FilterModule:
    def filters(self):
        return {"netbird_saved_interface_enabled": netbird_saved_interface_enabled}
