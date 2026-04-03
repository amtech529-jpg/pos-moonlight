import requests
import json

token = '5c742c3a2e868ac2fadfb685842b8d9e11ab778c'
headers = {
    'Authorization': 'Token ' + token,
    'Content-Type': 'application/json'
}

# Get order items
order_id = 'c7190ac2-01a6-4069-8557-c8f1703a688d'
resp = requests.get(f'http://127.0.0.1:8000/api/v1/order-items/?order_id={order_id}', headers=headers)
order_items = resp.json()['data']['order_items']

print("=== Testing create return with product_name fallback ===")
payload = {
    'order': order_id,
    'responsibility': 'NONE',
    'damage_charges': 0.0,
    'notes': 'test return with name fallback',
    'items': [
        {
            'product': item.get('product_id', ''),        # empty
            'order_item_id': item['id'],                   # fallback 1
            'product_name': item['product_name'],          # fallback 2
            'qty_sent': item['quantity'],
            'qty_returned': item['quantity'],
            'qty_damaged': 0,
            'qty_missing': 0,
            'damage_charge': 0.0,
            'condition_notes': '',
        }
        for item in order_items
    ],
    'restore_stock': False
}
print("Sending", len(payload['items']), "items")
for it in payload['items']:
    print(f"  product_name={it['product_name']}")

resp_create = requests.post('http://127.0.0.1:8000/api/v1/rental-returns/create/', headers=headers, json=payload)
print(f"\nCreate status: {resp_create.status_code}")
print(f"Create response: {resp_create.text[:3000]}")
