<script lang="ts">
  export let data;
  import { onMount } from "svelte";
  import { mailsStore } from "$lib/store/mails-store";
  import Loader from "$lib/components/loader.svelte";
  import { theme } from "$lib/store/theme";
  import { colors } from "$lib/store/colors";
  import { get } from "svelte/store";
  import { goto } from '$app/navigation';
  import ReplyPopup from "$lib/components/replyPopup.svelte";
  import MailThread from "$lib/components/mailThread.svelte";

  let showReplyPopup = false;
  let replyData = null;
  let buttonHovering = false;
  let loading = false;
  let mailData;
  let currentTheme;
  let currentColors;

  const unsubscribeTheme = theme.subscribe(value => {
    currentTheme = value;
    const colorsValue = get(colors);
    currentColors = colorsValue[currentTheme];
    if (typeof window !== "undefined") {
      if (value === 'dark') {
        document.documentElement.classList.add('dark');
      } else {
        document.documentElement.classList.remove('dark');
      }
    }
  });
  async function getMailById(id) {
    loading = true;
    mailData = await mailsStore.getMailById(id);
    // console.log(mailData, "mailData");
    loading = false;
  }

  onMount(() => {
    if (data && data.id) {
      getMailById(data.id);
    }
  });

  function openReplyPopup() {
  replyData = {
    to: mailData.ok[0].from,
    subject: `Re: ${mailData.ok[0].subject}`,
    body: `\n\n--- Original Message ---\n${mailData.ok[0].body}`,
    parentMailId: mailData.ok[0].id,
    attachments: mailData.ok[0].attachmentIds || [],
  };
  showReplyPopup = true;
}

</script>

  <div class="w-full p-1">
    {#if loading}
  <Loader message="Fetching email details..." />
{:else if mailData && Object.keys(mailData).length > 0}
  <div class="shadow-sm px-4 py-3 cursor-default">
    <h2 class="text-lg font-bold">{mailData.ok[0].subject}</h2>
    <p class="text-sm text-gray-600">From: {mailData.ok[0].from}</p>
    <p class="mt-2 whitespace-pre-wrap">{mailData.ok[0].body}</p>

   <button
      class="mt-4 px-4 py-2 rounded transition cursor-pointer"
      style="
        background-color: {currentColors.btn};
        color: {currentColors.btnText};
      "
      on:click={openReplyPopup}
      on:mouseover={() => buttonHovering = true}
      on:mouseout={() => buttonHovering = false}
    >
      Reply
    </button>
  </div>

  {#if showReplyPopup}
    <ReplyPopup 
      on:close={() => showReplyPopup = false} 
      {replyData} 
    />
  {/if}
  <div class="mt-6">
      <MailThread mails={mailData.ok.slice(1)} />
    </div>
{:else}
  <p class="text-gray-500">No email found.</p>
{/if}
  </div>

