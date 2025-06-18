<script>
  import { createEventDispatcher } from "svelte";
  const dispatch = createEventDispatcher();

  let to = "";
  let subject = "";
  let message = "";
  let minimized = false;

  function send() {
    alert(`Sending to: ${to}\nSubject: ${subject}\nMessage: ${message}`);
    // Add actual send logic here
  }

  function close() {
    dispatch("close");
  }

  function toggleMinimize() {
    minimized = !minimized;
  }
</script>

<div class="flex flex-col space-y-3 rounded-lg shadow p-0 bg-white">
  <div class="flex justify-between items-center mb-2">
    <h2 class="text-lg font-semibold">Write Mail</h2>
    <div class="space-x-2">
     <button
        aria-label="Minimize"
        on:click={toggleMinimize}
        class="text-sm px-2 py-1 rounded bg-gray-200 hover:bg-gray-300"
        >
        {#if minimized}
            <span>⬆</span>
        {:else}
            <span>➖</span>
        {/if}
        </button>
      <button
        aria-label="Close"
        on:click={close}
        class="text-sm px-2 py-1 rounded bg-red-500 text-white hover:bg-red-600"
      >
        ✖️ 
      </button>
    </div>
  </div>

  {#if !minimized}
    <input type="text" bind:value={to} placeholder="To" class="border p-2 rounded" />
    <input type="text" bind:value={subject} placeholder="Subject" class="border p-2 rounded" />
    <textarea bind:value={message} placeholder="Message" class="border p-2 rounded h-24"></textarea>
    <button on:click={send} class="bg-blue-600 text-white p-2 rounded hover:bg-blue-700 transition">Send</button>
  {/if}
</div>
