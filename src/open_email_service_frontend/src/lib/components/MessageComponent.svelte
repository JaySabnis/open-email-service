<script>
  import MessageList from "$lib/components/MessageList.svelte";
  import MessageDetails from "$lib/components/MessageDetails.svelte";
  
  let selectedMessage = null;
  let messageListKey = Date.now(); 

  function handleSelect(event) {
    if (!selectedMessage || selectedMessage.id !== event.detail.id) {
      selectedMessage = event.detail;
      messageListKey = Date.now();
    }
  }

  function handleClose() {
    selectedMessage = null;
    messageListKey = Date.now(); 
  }
</script>

<div class="flex w-full min-h-screen bg-white">
  <div class={selectedMessage ? "w-[30%]" : "w-full"} key={messageListKey}>
    <MessageList on:select={handleSelect} selectedMessage={selectedMessage} />
  </div>

  {#if selectedMessage}
    <div class="w-[70%] border-l bg-white">
      <MessageDetails message={selectedMessage} on:close={handleClose} />
    </div>
  {/if}
</div>