<script>
  import MessageList from "$lib/components/MessageList.svelte";
  import MessageDetails from "$lib/components/MessageDetails.svelte";
  
  export let pageType = "inbox";
  
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
    <MessageList 
      on:select={handleSelect} 
      selectedMessage={selectedMessage}
      pageType={pageType} 
    />
  </div>

  {#if selectedMessage}
    <div class="w-[70%] border-l border-gray-200 bg-white">
      <MessageDetails message={selectedMessage} on:close={handleClose} pageType={pageType}/>
    </div>
  {/if}
</div>