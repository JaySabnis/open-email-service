<script>
  import { onMount } from "svelte";
  import { mailsStore } from "$lib/store/mails-store";
  import Loader from "$lib/components/loader.svelte";

  let mails;
  let loading = true;
  async function getInboxMails() {
    loading = true;
    mails = await mailsStore.fetchInboxMails();
    const outgoingMails = await mailsStore.fetchOutboxMails();
    // console.log(mails[0], outgoingMails, "mails");
    loading = false;
  }

  onMount(async () => {
    await getInboxMails();
  });
</script>

{#if loading}
  <Loader message="Fetching your emails..." />
{:else if Array.isArray(mails[0]) && mails.length}
  <div class="w-full max-w-3xl mx-auto p-4 space-y-3">
    {#each mails[0] as msg, i}
      <div
        class="bg-white hover:bg-gray-50 transition border rounded-lg shadow-sm px-4 py-3 cursor-pointer flex justify-between items-start"
      >
        <div>
          <p class="font-semibold text-gray-800">
            {msg?.from || `Sender ${i + 1}`}
          </p>
          <p class="text-sm text-gray-600">{msg?.subject || 'No Subject'}</p>
        </div>
        <span class="text-xs text-gray-400"> {new Date(Number(msg.createdOn) / 1_000_000).toLocaleString()}</span>
      </div>
    {/each}
  </div>
{:else}
  <p class="text-gray-500 text-center">No messages to show.</p>
{/if}
