
import os
import django
from django.db import connection

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

with connection.cursor() as cursor:
    cursor.execute("SELECT COUNT(*) FROM \"order\"")
    count = cursor.fetchone()[0]
    print(f"Total records in 'order' table: {count}")

    cursor.execute("SELECT * FROM \"order\" LIMIT 5")
    rows = cursor.fetchall()
    for row in rows:
        print(row)
