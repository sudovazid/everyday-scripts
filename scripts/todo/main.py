tasks = []

def add_task():
    task = input("Please enter a task: ")
    tasks.append(task)
    print(f"Task '{task}' added to the list")

def list_task():
    if not tasks:
        print("There are no tasks currently.")
    else:
        print("Current Tasks:")
        for index, task in enumerate(tasks):
            print(f"Task #{index}. {task}")

def delete_task():
    list_task()
    try:
        taskToDelete = int(input("Enter the task index to delete: "))
        if taskToDelete >= 0 and taskToDelete < len(tasks):
            tasks.pop(taskToDelete)
            print(f"Task {taskToDelete} has been removed.")
        else:
            print(f"Task {taskToDelete} was not found.")
    except:
        print("Invalid input.")

if __name__ == "__main__":
    print("Welcome to the to do list app: ")
    while True:
        print("\n")
        print("Please select one of the following options")
        print("___________________________________________")
        print("1. Add task")
        print("2. Delete task")
        print("3. List task")
        print("4. Exit")

        choice = input("Enter your choice: ")

        if (choice == "1"):
            add_task()
        elif(choice == "2"):
            delete_task()
        elif(choice == "3"):
            list_task()
        elif(choice == "4"):
            break
        else:
            print("Invalid input, Please try again.")
    print("Goodbye 🙆")
