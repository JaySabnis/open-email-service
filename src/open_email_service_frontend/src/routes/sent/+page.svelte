<script>
  import MessageComponent from "$lib/components/MessageComponent.svelte";
  import NewSidebar from "$lib/components/NewSidebar.svelte";
  import WriteMail from "$lib/components/WriteMail.svelte";
  import { showWriteMail, closeWriteMail } from '$lib/store/ui';
</script>


<svelte:head>
  <title>Open Mail | Sent</title>
</svelte:head>

<div class="w-full">
  <MessageComponent pageType="sent" />

  {#if $showWriteMail}
    <div class="fixed bottom-0 right-30 w-100 max-w-full shadow-lg p-0 z-50"
         style="background-color: var(--background-color, white);">
      <WriteMail on:close={closeWriteMail} />
    </div>
  {/if}
</div>