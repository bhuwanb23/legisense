# Database Clear Tools

This directory contains tools to clear all data from the database tables while preserving the table structure. This is useful for testing, development, and resetting the database state.

## Available Tools

### 1. Django Management Command (Recommended)

**File**: `api/management/commands/clear_database.py`

**Usage**:
```bash
# Interactive mode (shows confirmation prompt)
python manage.py clear_database

# Skip confirmation prompt
python manage.py clear_database --confirm

# Clear specific tables only
python manage.py clear_database --tables simulation_sessions parsed_documents

# Clear all tables (default)
python manage.py clear_database --tables all
```

**Available Tables**:
- `all` - Clear all tables (default)
- `parsed_documents` - Document uploads and metadata
- `document_analysis` - AI analysis results
- `simulation_sessions` - Simulation sessions
- `timeline_nodes` - Timeline data
- `penalty_forecasts` - Penalty forecast data
- `exit_comparisons` - Exit scenario comparisons
- `narrative_outcomes` - Narrative outcomes
- `long_term_points` - Long-term forecast data
- `risk_alerts` - Risk alerts

### 2. Standalone Script

**File**: `clear_database.py`

**Usage**:
```bash
# Interactive mode
python clear_database.py

# Skip confirmation
python clear_database.py --confirm

# Clear specific tables
python clear_database.py --tables simulation_sessions parsed_documents
```

## Features

### ✅ **Safe Operation**
- **Preserves table structure** - Only deletes data, not tables
- **Transaction safety** - Uses database transactions for atomicity
- **Foreign key handling** - Clears tables in correct order to avoid constraint violations
- **Confirmation prompt** - Prevents accidental data loss

### ✅ **Comprehensive Coverage**
- Clears all related tables in the correct dependency order
- Handles both `ParsedDocument` and `SimulationSession` related data
- Supports selective table clearing

### ✅ **User-Friendly**
- **Visual feedback** - Shows record counts before and after
- **Progress indicators** - Real-time deletion progress
- **Summary report** - Detailed summary of what was cleared
- **Error handling** - Graceful error handling with rollback

## Example Output

```
🗑️  Database Clear Operation
==================================================
📊 parsed_documents: 12 records
📊 document_analysis: 11 records
📊 simulation_sessions: 12 records
📊 timeline_nodes: 10 records
📊 penalty_forecasts: 6 records
📊 exit_comparisons: 6 records
📊 narrative_outcomes: 6 records
📊 long_term_points: 6 records
📊 risk_alerts: 8 records
--------------------------------------------------
📈 Total records to delete: 77

⚠️  WARNING: This will permanently delete all data!
Tables will be preserved, but all rows will be removed.

Are you sure you want to continue? (yes/no): yes
🗑️  Cleared risk_alerts: 8 records
🗑️  Cleared long_term_points: 6 records
🗑️  Cleared narrative_outcomes: 6 records
🗑️  Cleared exit_comparisons: 6 records
🗑️  Cleared penalty_forecasts: 6 records
🗑️  Cleared timeline_nodes: 10 records
🗑️  Cleared simulation_sessions: 12 records
🗑️  Cleared document_analysis: 11 records
🗑️  Cleared parsed_documents: 12 records

✅ Database cleared successfully!

📊 Summary:
   • risk_alerts: 8 records deleted
   • long_term_points: 6 records deleted
   • narrative_outcomes: 6 records deleted
   • exit_comparisons: 6 records deleted
   • penalty_forecasts: 6 records deleted
   • timeline_nodes: 10 records deleted
   • simulation_sessions: 12 records deleted
   • document_analysis: 11 records deleted
   • parsed_documents: 12 records deleted
   • Total: 77 records deleted
```

## Use Cases

### 🧪 **Development & Testing**
- Reset database state between tests
- Clear test data after development sessions
- Prepare clean database for demos

### 🔄 **Data Management**
- Clear old simulation data
- Reset document analysis results
- Clean up uploaded files metadata

### 🚀 **Deployment**
- Prepare fresh database for production
- Clear development data before deployment
- Reset staging environment

## Safety Notes

⚠️ **Important**: This operation is **irreversible**. Once data is deleted, it cannot be recovered unless you have backups.

✅ **Safe to use** when:
- You have database backups
- You're in a development environment
- You want to reset test data
- You're preparing for a fresh start

❌ **Do NOT use** when:
- You have important production data
- You don't have backups
- You're unsure about the data

## Database Tables Affected

The following tables will be cleared (in dependency order):

1. **`SimulationRiskAlert`** - Risk alerts
2. **`SimulationLongTermPoint`** - Long-term forecast points
3. **`SimulationNarrativeOutcome`** - Narrative outcomes
4. **`SimulationExitComparison`** - Exit scenario comparisons
5. **`SimulationPenaltyForecast`** - Penalty forecasts
6. **`SimulationTimelineNode`** - Timeline nodes
7. **`SimulationSession`** - Simulation sessions
8. **`DocumentAnalysis`** - Document analysis results
9. **`ParsedDocument`** - Parsed documents

## Troubleshooting

### Permission Errors
```bash
# Make sure you're in the correct directory
cd legisense_backend

# Ensure Django can access the database
python manage.py check
```

### Import Errors
```bash
# Make sure Django is properly set up
python manage.py shell
```

### Database Locked
```bash
# Stop any running Django server
# Then run the clear command
python manage.py clear_database
```
