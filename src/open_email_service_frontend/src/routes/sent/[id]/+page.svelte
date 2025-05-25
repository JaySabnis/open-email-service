<script lang="ts">
  export let data;
  import { onMount } from "svelte";
  import { mailsStore } from "$lib/store/mails-store";
  import Loader from "$lib/components/loader.svelte";
  import { theme } from "$lib/store/theme";
  import { colors } from "$lib/store/colors";
  import { get } from "svelte/store";
  import { goto } from '$app/navigation';

  let loading = false;
  let mailData;
  async function getMailById(id) {
    loading = true;
    mailData = await mailsStore.getMailById(id);
    console.log(mailData, "mailData");
    loading = false;
  }

  onMount(() => {
    if (data && data.id) {
      getMailById(data.id);
    }
  });

</script>

  <div class="w-full p-1">
    {#if loading}
      <Loader message="Fetching email details..." />
    {:else if mailData && Object.keys(mailData).length > 0}
      <div class=" shadow-sm px-4 py-3">
        <h2 class="text-lg font-bold">{mailData.ok[0].subject}</h2>
        <p class="text-sm text-gray-600">From: {mailData.ok[0].from}</p>
        <p class="mt-2">{mailData.ok[0].body}</p>
      </div>
    {:else}
      <p class="text-gray-500">No email found.</p>
    {/if}
  </div>

