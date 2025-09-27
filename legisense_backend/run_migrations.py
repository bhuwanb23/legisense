#!/usr/bin/env python
"""
Simple script to run Django migrations on production.
Run this on Render.com if migrations don't run automatically.
"""
import os
import sys
import django
from pathlib import Path

# Add the project directory to Python path
project_dir = Path(__file__).resolve().parent
sys.path.insert(0, str(project_dir))

# Set Django settings
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'legisense_backend.settings')
django.setup()

from django.core.management import call_command
from django.db import connection

def main():
    print("🚀 Starting database migration...")
    
    try:
        # Test database connection
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
        print("✅ Database connection successful")
        
        # Run migrations
        print("📦 Running migrations...")
        call_command('migrate', verbosity=2)
        print("✅ Migrations completed successfully")
        
        # Check tables
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT table_name 
                FROM information_schema.tables 
                WHERE table_schema = 'public' 
                AND table_name LIKE 'api_%'
            """)
            tables = cursor.fetchall()
            
        if tables:
            print(f"✅ Found {len(tables)} API tables: {[t[0] for t in tables]}")
        else:
            print("⚠️  No API tables found")
            
        print("🎉 Database setup completed!")
        
    except Exception as e:
        print(f"❌ Error: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()
