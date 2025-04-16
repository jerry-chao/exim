import { Socket } from "phoenix";

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let token = window.userToken;
console.log("user login with token ", csrfToken);
console.log("user login with window token ", token);
let socket = new Socket("/socket", { params: { token: token } });
socket.connect();

let channel = socket.channel("room:lobby", {});
let chatInput = document.querySelector("#chat-input");
let messagesContainer = document.querySelector("#messages");

if (chatInput && messagesContainer) {
    chatInput.addEventListener("keypress", (event) => {
        if (event.key === "Enter") {
            channel.push("new_msg", { body: chatInput.value });
            chatInput.value = "";
        }
    });
    channel.on("new_msg", (payload) => {
        let messageItem = document.createElement("p");
        messageItem.innerText = `[${Date()}] ${payload.body}`;
        messagesContainer.appendChild(messageItem);
    });

    channel
        .join()
        .receive("ok", (resp) => {
            console.log("Joined successfully", resp);
        })
        .receive("error", (resp) => {
            console.log("Unable to join", resp);
        });
}

export default socket;
