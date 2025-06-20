<script>
  import MessageList from "$lib/components/MessageList.svelte";
  import MessageDetails from "$lib/components/MessageDetails.svelte";
  // import { pageLoading } from '$lib/store/loading';
  // import Loader from "$lib/components/Loader.svelte";

  let selectedMessage = null;

  function handleSelect(event) {
    selectedMessage = event.detail;
    // console.log("Selected message in parent:", selectedMessage);
  }

  function handleClose() {
    selectedMessage = null;
  }
</script>

  <div class="flex w-full min-h-screen bg-gray-100">

    <div class={selectedMessage ? "w-[30%]" : "w-full"}>
      <MessageList on:select={handleSelect} />
    </div>

    {#if selectedMessage}
      <div class="w-[70%] border-l bg-white ">
        <MessageDetails message={selectedMessage} on:close={handleClose} />
      </div>
    {/if}
  </div>