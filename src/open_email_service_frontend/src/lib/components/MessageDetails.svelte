<script>
  import { createEventDispatcher } from 'svelte';
  export let message;

  const dispatch = createEventDispatcher();

  function close() {
    dispatch('close');
  }
</script>

<div class="p-6 h-screen overflow-y-auto bg-white border-l flex flex-col">
  <div class="flex justify-between items-center mb-4">
    <h2 class="text-xl font-bold">Message from {message.sender}</h2>
    <button
      on:click={close}
      class="text-sm px-2 py-1 rounded bg-red-500 text-white hover:bg-red-600"
      aria-label="Close message details"
    >
      ✖️ Close
    </button>
  </div>
  <p class="text-gray-700 text-base flex-grow">{message.text}</p>
</div>
