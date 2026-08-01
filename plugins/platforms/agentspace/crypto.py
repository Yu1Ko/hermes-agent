"""
Agentspace crypto utilities.

AES-256-GCM encryption/decryption for wps_sid tokens.
Matches the TypeScript implementation in @ecis/agentspace.
"""

import os
from hashlib import scrypt


ALGORITHM = "aes-256-gcm"
KEY_LENGTH = 32
IV_LENGTH = 12  # GCM recommended
SALT_LENGTH = 16
DEFAULT_KEY_SOURCE = "openclaw_agentspace"

# Try to import cryptography; fall back to PyCryptodome
try:
    from cryptography.hazmat.primitives.ciphers.aead import AESGCM
    _USE_CRYPTOGRAPHY = True
except ImportError:
    try:
        from Crypto.Cipher import AES as _AES
        _USE_CRYPTOGRAPHY = False
    except ImportError:
        _USE_CRYPTOGRAPHY = None  # No crypto lib available


def _derive_key(app_id: str, salt: bytes) -> bytes:
    """Derive 32-byte AES key from app_id using scrypt."""
    key_source = (app_id or DEFAULT_KEY_SOURCE).encode("utf-8")
    return scrypt(key_source, salt=salt, n=2**14, r=8, p=1, dklen=KEY_LENGTH)


def encrypt_wps_sid(wps_sid: str, app_id: str = "") -> str:
    """Encrypt wps_sid using AES-256-GCM.

    Returns: "salt_hex:iv_hex:auth_tag_hex:ciphertext_hex"
    """
    if not wps_sid:
        raise ValueError("wpsSid cannot be empty")

    salt = os.urandom(SALT_LENGTH)
    key = _derive_key(app_id, salt)
    iv = os.urandom(IV_LENGTH)

    if _USE_CRYPTOGRAPHY is True:
        aesgcm = AESGCM(key)
        ciphertext = aesgcm.encrypt(iv, wps_sid.encode("utf-8"), None)
        # AESGCM.encrypt returns ciphertext with auth tag appended
        encrypted = ciphertext[:-16]
        auth_tag = ciphertext[-16:]
    elif _USE_CRYPTOGRAPHY is False:
        cipher = _AES.new(key, _AES.MODE_GCM, nonce=iv)
        encrypted, auth_tag = cipher.encrypt_and_digest(wps_sid.encode("utf-8"))
    else:
        raise RuntimeError("No crypto library available (install cryptography or pycryptodome)")

    return f"{salt.hex()}:{iv.hex()}:{auth_tag.hex()}:{encrypted.hex()}"


def decrypt_wps_sid(encrypted_token: str, app_id: str = "") -> str:
    """Decrypt wps_sid from AES-256-GCM encrypted token.

    Input format: "salt_hex:iv_hex:auth_tag_hex:ciphertext_hex"
    """
    if not encrypted_token:
        raise ValueError("encryptedToken cannot be empty")

    parts = encrypted_token.split(":")
    if len(parts) != 4:
        raise ValueError(
            "Invalid encrypted token format. Expected: salt:iv:authTag:encryptedData"
        )

    salt_hex, iv_hex, auth_tag_hex, encrypted_hex = parts
    salt = bytes.fromhex(salt_hex)
    key = _derive_key(app_id, salt)
    iv = bytes.fromhex(iv_hex)
    auth_tag = bytes.fromhex(auth_tag_hex)
    encrypted = bytes.fromhex(encrypted_hex)

    if _USE_CRYPTOGRAPHY is True:
        aesgcm = AESGCM(key)
        ciphertext = encrypted + auth_tag
        decrypted = aesgcm.decrypt(iv, ciphertext, None)
    elif _USE_CRYPTOGRAPHY is False:
        cipher = _AES.new(key, _AES.MODE_GCM, nonce=iv)
        decrypted = cipher.decrypt_and_verify(encrypted, auth_tag)
    else:
        raise RuntimeError("No crypto library available (install cryptography or pycryptodome)")

    return decrypted.decode("utf-8")
