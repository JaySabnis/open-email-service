<script>
  import { mailsStore } from '$lib/store/mails-store';
  import { createEventDispatcher } from 'svelte';
  import { onMount } from 'svelte';

  export let message;

  const dispatch = createEventDispatcher();
  let currentTheme;
  let currentColors;
  let mailData;

  function close() {
    dispatch('close');
  }

  async function getMail() {
   const mail = await mailsStore.getMailById(message.id);
   console.log('Fetched mail:', mail);
    if (mail) {
      message = mail;
      mailData = mail?.ok?.[0]
    } else {
      console.error('Mail not found');
    }
  }

  onMount(async () => {
   await getMail();
  });
</script>

<div 
  class="p-6 h-screen overflow-y-auto flex flex-col"
>
  <div class="flex justify-between items-center mb-4">
    <div>
      <h2 class="text-xl font-bold" >
        {mailData?.subject || 'No Subject'}
      </h2>
      <p class="text-sm" >
        From: {mailData?.from || 'Unknown Sender'}
      </p>
      <p class="text-xs">
        {new Date(Number(mailData?.createdOn) / 1_000_000).toLocaleString()}
      </p>
    </div>
    <button
      on:click={close}
      class="text-sm px-3 py-1 rounded hover:opacity-90 transition-opacity"
      aria-label="Close message details"
    >
      ✖ Close
    </button>
  </div>

  <div class="border-t pt-4 flex-grow">
    {#if mailData?.preview}
      <div class="whitespace-pre-line" >
        {mailData.preview}
      </div>
    {:else}
      <p >No message content</p>
    {/if}
  </div>
</div>