
# setup.py
from setuptools import setup, find_packages

setup(
    name="productivity-tools",
    version="1.0.0",
    packages=find_packages(),
    install_requires=[
        'pandas>=1.5.0',
        'rich>=10.0.0',
        'schedule>=1.1.0',
        'pytz>=2022.1',
        'SQLAlchemy>=1.4.0',
        'python-dateutil>=2.8.2',
        'notify-py>=0.3.3',
    ],
    extras_require={
        'windows': ['win10toast>=0.9'],
    },
    author="Your Name",
    author_email="your.email@example.com",
    description="A comprehensive productivity suite for developers",
    long_description=open("README.md").read(),
    long_description_content_type="text/markdown",
    url="https://github.com/yourusername/productivity-tools",
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
    ],
    python_requires=">=3.7",
)

import datetime
import json
import re
import sqlite3
from dataclasses import dataclass
from datetime import datetime, timedelta
from pathlib import Path
from typing import List, Dict, Optional
import pandas as pd
from rich.console import Console
from rich.table import Table
import pytz
import schedule
import time
import subprocess
import platform
from datetime import date

# Installation verification function
def verify_dependencies():
    """Verify that all required dependencies are installed correctly."""
    required_packages = {
        'pandas': 'pd',
        'rich': 'rich',
        'schedule': 'schedule',
        'pytz': 'pytz',
        'sqlite3': 'sqlite3',
        'dateutil': 'dateutil'
    }
    
    missing_packages = []
    for package, module in required_packages.items():
        try:
            __import__(module)
        except ImportError:
            missing_packages.append(package)
    
    if missing_packages:
        raise ImportError(
            f"Missing required packages: {', '.join(missing_packages)}. "
            f"Please install them using 'pip install {' '.join(missing_packages)}'"
        )

@dataclass
class Task:
    id: int
    title: str
    description: str
    priority: int  # 1 (highest) to 5 (lowest)
    deadline: datetime
    tags: List[str]
    estimated_hours: float
    actual_hours: float = 0.0
    status: str = "pending"  # pending, in_progress, completed
    project: str = "default"

class ProductivitySuite:
    def __init__(self, db_path: str = "productivity.db"):
        # Verify dependencies before initializing
        verify_dependencies()
        
        self.db_path = db_path
        self.console = Console()
        self.setup_database()
        
    def setup_database(self):
        """Initialize SQLite database with necessary tables."""
        conn = sqlite3.connect(self.db_path)
        c = conn.cursor()
        
        # Tasks table
        c.execute('''
            CREATE TABLE IF NOT EXISTS tasks
            (id INTEGER PRIMARY KEY,
             title TEXT,
             description TEXT,
             priority INTEGER,
             deadline TIMESTAMP,
             tags TEXT,
             estimated_hours REAL,
             actual_hours REAL,
             status TEXT,
             project TEXT)
        ''')
        
        # Time tracking table
        c.execute('''
            CREATE TABLE IF NOT EXISTS time_entries
            (id INTEGER PRIMARY KEY,
             task_id INTEGER,
             start_time TIMESTAMP,
             end_time TIMESTAMP,
             description TEXT,
             project TEXT)
        ''')
        
        # Meetings table
        c.execute('''
            CREATE TABLE IF NOT EXISTS meetings
            (id INTEGER PRIMARY KEY,
             title TEXT,
             start_time TIMESTAMP,
             end_time TIMESTAMP,
             link TEXT,
             platform TEXT,
             notes TEXT)
        ''')
        
        conn.commit()
        conn.close()

    def start_pomodoro(self, work_minutes: int = 25, break_minutes: int = 5):
        """Enhanced Pomodoro timer with task tracking."""
        def notify(message):
            if platform.system() == "Darwin":  # macOS
                subprocess.run(["osascript", "-e", f'display notification "{message}" with title "Pomodoro"'])
            elif platform.system() == "Linux":
                subprocess.run(["notify-send", "Pomodoro", message])
            elif platform.system() == "Windows":
                from win10toast import ToastNotifier
                toaster = ToastNotifier()
                toaster.show_toast("Pomodoro", message)

        while True:
            # Work session
            self.console.print(f"[green]Starting {work_minutes} minute work session...[/green]")
            notify("Work session started")
            time.sleep(work_minutes * 60)
            
            # Break time
            self.console.print(f"[yellow]Take a {break_minutes} minute break![/yellow]")
            notify("Break time!")
            time.sleep(break_minutes * 60)

    def extract_meeting_links(self, text: str) -> Dict[str, str]:
        """Extract meeting links from text."""
        patterns = {
            'zoom': r'https:\/\/[a-zA-Z0-9.-]+\.zoom\.us\/[a-zA-Z0-9\/\?=&]+',
            'teams': r'https:\/\/teams\.microsoft\.com\/[a-zA-Z0-9\/\?=&]+',
            'meet': r'https:\/\/meet\.google\.com\/[a-zA-Z0-9\-]+'
        }
        
        links = {}
        for platform, pattern in patterns.items():
            found = re.findall(pattern, text)
            if found:
                links[platform] = found[0]
        
        return links

    def add_meeting(self, title: str, start_time: datetime, end_time: datetime, 
                   description: str, auto_extract_links: bool = True):
        """Add a meeting with automatic link extraction."""
        conn = sqlite3.connect(self.db_path)
        c = conn.cursor()
        
        links = self.extract_meeting_links(description) if auto_extract_links else {}
        platform = next(iter(links.keys())) if links else None
        link = next(iter(links.values())) if links else None
        
        c.execute('''
            INSERT INTO meetings (title, start_time, end_time, link, platform, notes)
            VALUES (?, ?, ?, ?, ?, ?)
        ''', (title, start_time, end_time, link, platform, description))
        
        conn.commit()
        conn.close()
        
        # Schedule reminder
        reminder_time = start_time - timedelta(minutes=5)
        schedule.every().day.at(reminder_time.strftime("%H:%M")).do(
            self.send_meeting_reminder, title, link, platform
        )

    def generate_timesheet(self, start_date: date, end_date: date, 
                         project: Optional[str] = None) -> pd.DataFrame:
        """Generate detailed timesheet with project filtering."""
        conn = sqlite3.connect(self.db_path)
        
        query = '''
            SELECT t.project, t.title, te.start_time, te.end_time, te.description
            FROM time_entries te
            JOIN tasks t ON te.task_id = t.id
            WHERE DATE(te.start_time) BETWEEN ? AND ?
        '''
        
        if project:
            query += ' AND t.project = ?'
            params = (start_date, end_date, project)
        else:
            params = (start_date, end_date)
            
        df = pd.read_sql_query(query, conn, params=params)
        conn.close()
        
        # Calculate duration and format timesheet
        df['duration'] = pd.to_datetime(df['end_time']) - pd.to_datetime(df['start_time'])
        df['hours'] = df['duration'].dt.total_seconds() / 3600
        
        # Group by project and task
        summary = df.groupby(['project', 'title'])['hours'].sum().reset_index()
        
        return summary

    def track_time(self, task_id: int, start_time: Optional[datetime] = None):
        """Start tracking time for a task."""
        if not start_time:
            start_time = datetime.now()
            
        conn = sqlite3.connect(self.db_path)
        c = conn.cursor()
        
        # Get task details
        c.execute('SELECT project FROM tasks WHERE id = ?', (task_id,))
        project = c.fetchone()[0]
        
        c.execute('''
            INSERT INTO time_entries (task_id, start_time, project)
            VALUES (?, ?, ?)
        ''', (task_id, start_time, project))
        
        conn.commit()
        conn.close()
        
        self.console.print(f"[green]Started tracking time for task {task_id}[/green]")

    def stop_tracking(self, task_id: int, end_time: Optional[datetime] = None):
        """Stop tracking time for a task."""
        if not end_time:
            end_time = datetime.now()
            
        conn = sqlite3.connect(self.db_path)
        c = conn.cursor()
        
        c.execute('''
            UPDATE time_entries 
            SET end_time = ?
            WHERE task_id = ? AND end_time IS NULL
        ''', (end_time, task_id))
        
        # Update actual hours in tasks table
        c.execute('''
            UPDATE tasks
            SET actual_hours = (
                SELECT SUM((julianday(end_time) - julianday(start_time)) * 24)
                FROM time_entries
                WHERE task_id = ? AND end_time IS NOT NULL
            )
            WHERE id = ?
        ''', (task_id, task_id))
        
        conn.commit()
        conn.close()

    def prioritize_tasks(self) -> List[Task]:
        """Prioritize tasks using weighted scoring."""
        conn = sqlite3.connect(self.db_path)
        c = conn.cursor()
        
        c.execute('''
            SELECT id, title, description, priority, deadline, tags,
                   estimated_hours, actual_hours, status, project
            FROM tasks
            WHERE status != 'completed'
        ''')
        
        tasks = []
        for row in c.fetchall():
            task = Task(
                id=row[0], title=row[1], description=row[2],
                priority=row[3], deadline=datetime.fromisoformat(row[4]),
                tags=row[5].split(','), estimated_hours=row[6],
                actual_hours=row[7], status=row[8], project=row[9]
            )
            tasks.append(task)
            
        conn.close()
        
        # Calculate priority score
        def calculate_priority_score(task: Task) -> float:
            time_until_deadline = (task.deadline - datetime.now()).total_seconds()
            deadline_score = 100 if time_until_deadline < 86400 else (100000 / time_until_deadline)
            
            priority_score = (
                (6 - task.priority) * 20 +  # Priority weight
                deadline_score +            # Deadline urgency
                (task.estimated_hours * 5)  # Effort required
            )
            
            # Adjust score based on tags
            if 'urgent' in task.tags:
                priority_score *= 1.5
            if 'blocking' in task.tags:
                priority_score *= 1.3
                
            return priority_score
            
        # Sort tasks by priority score
        prioritized_tasks = sorted(
            tasks,
            key=lambda t: calculate_priority_score(t),
            reverse=True
        )
        
        return prioritized_tasks

    def display_dashboard(self):
        """Display productivity dashboard."""
        prioritized_tasks = self.prioritize_tasks()
        
        # Create tasks table
        table = Table(title="Task Dashboard")
        table.add_column("Priority", justify="center", style="cyan")
        table.add_column("Task", style="green")
        table.add_column("Deadline", justify="right", style="magenta")
        table.add_column("Progress", justify="right", style="yellow")
        
        for task in prioritized_tasks[:10]:  # Show top 10 tasks
            progress = f"{(task.actual_hours / task.estimated_hours * 100):.1f}%" \
                if task.estimated_hours > 0 else "N/A"
            
            table.add_row(
                str(task.priority),
                task.title,
                task.deadline.strftime("%Y-%m-%d %H:%M"),
                progress
            )
            
        self.console.print(table)

def main():
    try:
        # Verify dependencies first
        verify_dependencies()
        
        # Create instance of ProductivitySuite
        suite = ProductivitySuite()
        
        # Example usage
        suite.add_meeting(
            "Team Standup",
            datetime.now().replace(hour=10, minute=0),
            datetime.now().replace(hour=10, minute=30),
            "Daily standup https://zoom.us/j/123456789"
        )
        
        # Start time tracking for a task
        suite.track_time(1)
        
        # Generate timesheet
        timesheet = suite.generate_timesheet(
            date.today() - timedelta(days=7),
            date.today()
        )
        
        # Display dashboard
        suite.display_dashboard()
        
    except ImportError as e:
        print(f"Error: {e}")
        print("\nPlease install the required dependencies using one of these methods:")
        print("\n1. Using requirements.txt:")
        print("   pip install -r requirements.txt")
        print("\n2. Using setup.py:")
        print("   pip install .")
        print("\n3. Direct installation:")
        print("   pip install pandas rich schedule pytz SQLAlchemy python-dateutil notify-py")
        
    except Exception as e:
        print(f"An error occurred: {e}")

if __name__ == "__main__":
    main()