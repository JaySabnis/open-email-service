<script>
  import MessageComponent from "$lib/components/MessageComponent.svelte";
  import NewSidebar from "$lib/components/NewSidebar.svelte";
  import WriteMail from "$lib/components/WriteMail.svelte";
  import { showWriteMail, closeWriteMail } from '$lib/store/ui';
  import { navigating } from '$app/stores';
  import { onDestroy } from 'svelte';

  const unsubscribe = navigating.subscribe(($navigating) => {
    if ($navigating) {
      closeWriteMail();
    }
  });

  onDestroy(unsubscribe);
</script>

<div class="w-full">
  <MessageComponent />

  {#if $showWriteMail}
    <div class="fixed bottom-0 right-30 w-100 max-w-full shadow-lg p-0 z-50"
         style="background-color: var(--background-color, white);">
      <WriteMail on:close={closeWriteMail} />
    </div>
  {/if}
</div>