<script>
  import { createEventDispatcher } from "svelte";

  const dispatch = createEventDispatcher();

  let searchTerm = "";

  let messages = [
    { id: 1, sender: "Alice", subject: "Meeting update", text: "Hey there!" },
    { id: 2, sender: "Bob", subject: "Greetings", text: "Hello, how are you?" },
    { id: 3, sender: "Charlie", subject: "Plan for tomorrow", text: "Let's meet tomorrow." }
  ];

  function selectMessage(msg) {
    dispatch("select", msg);
  }

  // Filter messages by subject based on searchTerm (case-insensitive)
  $: filteredMessages = messages.filter(msg =>
    msg.subject.toLowerCase().includes(searchTerm.toLowerCase())
  );
</script>

<div class="space-y-4 p-6 overflow-y-auto h-screen bg-white">
  <h2 class="text-xl font-bold mb-4">Messages</h2>
  
  <input
    type="text"
    placeholder="Search by subject..."
    bind:value={searchTerm}
    class="w-full mb-4 p-2 border rounded"
  />
  
  {#each filteredMessages as msg}
    <div
      class="p-4 bg-gray-100 hover:bg-gray-200 rounded cursor-pointer border"
      on:click={() => selectMessage(msg)}
    >
      <p class="font-semibold">{msg.sender}</p>
      <p class="text-sm font-medium text-gray-800 truncate">{msg.subject}</p>
      <p class="text-sm text-gray-600 truncate">{msg.text}</p>
    </div>
  {/each}

  {#if filteredMessages.length === 0}
    <p class="text-gray-500 text-center mt-6">No messages found.</p>
  {/if}
</div>
