#!/usr/bin/env python3
import sys
import argparse
from getpass import getpass
from bit import Key
from bit.exceptions import InsufficientFunds

def main():
    """
    Constructs and broadcasts a Bitcoin transaction with an OP_RETURN output
    to anchor a data hash onto the Layer 1 blockchain.
    """
    parser = argparse.ArgumentParser(
        description="Helix L1 Anchor Tool: Anchor a data hash onto the Bitcoin blockchain.",
        epilog="The private key will be requested securely and is not stored."
    )
    parser.add_argument(
        "op_return_data",
        type=str,
        help="The 32-byte data hash (in hex) to be anchored in the OP_RETURN output."
    )
    
    args = parser.parse_args()

    # 1. Validate the input data
    op_return_hex = args.op_return_data
    if len(op_return_hex) != 64 or not all(c in '0123456789abcdefABCDEF' for c in op_return_hex):
        print("❌ ERROR: op_return_data must be a 64-character hex string (32 bytes).")
        sys.exit(1)

    print("--- Helix L1 Anchor Tool ---")
    print(f"Data to be anchored: {op_return_hex}")
    
    # 2. Securely get the private key from the Operator
    try:
        private_key_wif = getpass("🔑 Please enter your Private Key (WIF) to sign the transaction: ")
        if not private_key_wif:
            print("❌ ERROR: Private key cannot be empty.")
            sys.exit(1)
        
        # 3. Load the key and check balance
        key = Key(private_key_wif)
        balance = key.get_balance('sats')
        print(f"✅ Key loaded successfully. Address: {key.address}")
        print(f"💰 Current balance: {balance} sats")

        if int(balance) < 1000: # A reasonable minimum for fee + dust
            print("⚠️ WARNING: Balance may be too low to cover transaction fees.")

    except ValueError as e:
        print(f"❌ ERROR: Invalid Private Key format. Details: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"❌ An unexpected error occurred while loading the key: {e}")
        sys.exit(1)

    # 4. Construct and broadcast the transaction
    try:
        print("""
Constructing and broadcasting transaction...
""")
        # The bit library's send() function with a message automatically creates
        # an OP_RETURN output. It also handles UTXO selection, fee calculation,
        # and sending the change back to the source address.
        # The "burn" is the transaction fee paid to the miners.
        txid = key.send([], message=op_return_hex)
        
        print("""
✅ ANCHORING TRANSACTION BROADCAST COMPLETE
""")
        print(f"   TXID: {txid}")
        print("   This TXID is the permanent, verifiable proof of your ledger's integrity.")
        print("   You can now notarize this TXID or view it on a block explorer.")

    except InsufficientFunds:
        print("❌ ERROR: Insufficient funds in the wallet to cover the transaction fee.")
        sys.exit(1)
    except Exception as e:
        print(f"❌ An unexpected error occurred during the transaction: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
