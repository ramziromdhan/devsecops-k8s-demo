# zap-hook.py
# Ignorer les règles non pertinentes pour une API REST sans frontend

def zap_started(zap, target):
    """Configuration au démarrage du scan."""
    # Désactiver les règles cookie/session (API sans cookies)
    zap.pscan.disable_scanners('10054')  # Cookie Without Secure Flag
    zap.pscan.disable_scanners('10096')  # Timestamp Disclosure