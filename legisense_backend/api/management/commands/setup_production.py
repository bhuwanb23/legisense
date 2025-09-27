"""
Management command to set up production database.
This command ensures all migrations are applied and creates necessary data.
"""
from django.core.management.base import BaseCommand
from django.core.management import call_command
from django.db import connection
from django.conf import settings


class Command(BaseCommand):
    help = 'Set up production database with migrations and initial data'

    def handle(self, *args, **options):
        self.stdout.write(
            self.style.SUCCESS('Starting production database setup...')
        )
        
        # Check database connection
        try:
            with connection.cursor() as cursor:
                cursor.execute("SELECT 1")
            self.stdout.write(
                self.style.SUCCESS('✓ Database connection successful')
            )
        except Exception as e:
            self.stdout.write(
                self.style.ERROR(f'✗ Database connection failed: {e}')
            )
            return

        # Run migrations
        self.stdout.write('Running database migrations...')
        try:
            call_command('migrate', verbosity=2)
            self.stdout.write(
                self.style.SUCCESS('✓ Migrations completed successfully')
            )
        except Exception as e:
            self.stdout.write(
                self.style.ERROR(f'✗ Migrations failed: {e}')
            )
            return

        # Check if tables exist
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT table_name 
                FROM information_schema.tables 
                WHERE table_schema = 'public' 
                AND table_name LIKE 'api_%'
            """)
            tables = cursor.fetchall()
            
        if tables:
            self.stdout.write(
                self.style.SUCCESS(f'✓ Found {len(tables)} API tables: {[t[0] for t in tables]}')
            )
        else:
            self.stdout.write(
                self.style.WARNING('⚠ No API tables found after migration')
            )

        self.stdout.write(
            self.style.SUCCESS('🎉 Production database setup completed!')
        )
