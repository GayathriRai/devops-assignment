const API_URL = "/api";

const todoForm = document.getElementById("todoForm");
const titleInput = document.getElementById("title");
const descriptionInput = document.getElementById("description");

const todoList = document.getElementById("todoList");

const totalTasks = document.getElementById("totalTasks");
const completedTasks = document.getElementById("completedTasks");
const remainingTasks = document.getElementById("remainingTasks");

const taskSummary = document.getElementById("taskSummary");
const connectionStatus = document.getElementById("connectionStatus");

const refreshButton = document.getElementById("refreshButton");
const toast = document.getElementById("toast");


function showToast(message) {
    toast.textContent = message;
    toast.classList.add("show");

    setTimeout(() => {
        toast.classList.remove("show");
    }, 2500);
}


async function checkHealth() {
    try {
        const response = await fetch(`${API_URL}/health`);

        if (!response.ok) {
            throw new Error("Backend unavailable");
        }

        const data = await response.json();

        if (data.status === "healthy") {
            connectionStatus.textContent = "API connected";
        } else {
            connectionStatus.textContent = "Database unavailable";
        }

    } catch (error) {
        connectionStatus.textContent = "API unavailable";
    }
}


async function loadTodos() {

    try {

        const response = await fetch(`${API_URL}/todos`);

        if (!response.ok) {
            throw new Error("Unable to load todos");
        }

        const todos = await response.json();

        renderTodos(todos);

    } catch (error) {

        todoList.innerHTML = `
            <div class="empty-state">
                <div class="empty-icon">⚠️</div>
                <h3>Unable to load tasks</h3>
                <p>Make sure the backend and database are running.</p>
            </div>
        `;

    }
}


function renderTodos(todos) {

    const completed = todos.filter(
        todo => todo.completed
    ).length;

    const remaining = todos.length - completed;

    totalTasks.textContent = todos.length;
    completedTasks.textContent = completed;
    remainingTasks.textContent = remaining;

    taskSummary.textContent =
        todos.length === 1
            ? "1 task in your list"
            : `${todos.length} tasks in your list`;


    if (todos.length === 0) {

        todoList.innerHTML = `
            <div class="empty-state">
                <div class="empty-icon">✨</div>
                <h3>No tasks yet</h3>
                <p>Create your first task and start getting things done.</p>
            </div>
        `;

        return;
    }


    todoList.innerHTML = todos.map(todo => `

        <div
            class="todo-item ${todo.completed ? "completed" : ""}"
            data-id="${todo.id}"
        >

            <button
                class="check-button"
                onclick="toggleTodo(${todo.id}, ${!todo.completed})"
                title="Mark complete"
            >
                ${todo.completed ? "✓" : ""}
            </button>

            <div class="todo-content">

                <div class="todo-title">
                    ${escapeHtml(todo.title)}
                </div>

                ${
                    todo.description
                        ? `
                        <div class="todo-description">
                            ${escapeHtml(todo.description)}
                        </div>
                        `
                        : ""
                }

            </div>

            <button
                class="delete-button"
                onclick="deleteTodo(${todo.id})"
                title="Delete task"
            >
                🗑
            </button>

        </div>

    `).join("");
}


async function createTodo(event) {

    event.preventDefault();

    const title = titleInput.value.trim();
    const description = descriptionInput.value.trim();

    if (!title) {
        showToast("Please enter a task title.");
        return;
    }


    try {

        const response = await fetch(`${API_URL}/todos`, {

            method: "POST",

            headers: {
                "Content-Type": "application/json"
            },

            body: JSON.stringify({
                title,
                description
            })

        });


        const data = await response.json();


        if (!response.ok) {
            throw new Error(data.error || "Unable to create task");
        }


        titleInput.value = "";
        descriptionInput.value = "";

        showToast("Task created successfully ✨");

        await loadTodos();

        titleInput.focus();

    } catch (error) {

        showToast(error.message);

    }
}


async function toggleTodo(todoId, completed) {

    try {

        const response = await fetch(
            `${API_URL}/todos/${todoId}`,
            {
                method: "PUT",

                headers: {
                    "Content-Type": "application/json"
                },

                body: JSON.stringify({
                    completed
                })
            }
        );


        if (!response.ok) {
            throw new Error("Unable to update task");
        }


        await loadTodos();

        showToast(
            completed
                ? "Task completed 🎉"
                : "Task marked as active"
        );

    } catch (error) {

        showToast(error.message);

    }
}


async function deleteTodo(todoId) {

    const confirmed = confirm(
        "Are you sure you want to delete this task?"
    );

    if (!confirmed) {
        return;
    }


    try {

        const response = await fetch(
            `${API_URL}/todos/${todoId}`,
            {
                method: "DELETE"
            }
        );


        if (!response.ok) {
            throw new Error("Unable to delete task");
        }


        await loadTodos();

        showToast("Task deleted");

    } catch (error) {

        showToast(error.message);

    }
}


function escapeHtml(value) {

    const div = document.createElement("div");

    div.textContent = value;

    return div.innerHTML;
}


todoForm.addEventListener(
    "submit",
    createTodo
);


refreshButton.addEventListener(
    "click",
    loadTodos
);


checkHealth();
loadTodos();