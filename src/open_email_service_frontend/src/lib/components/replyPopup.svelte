<script>
  export let replyData;
  import { createEventDispatcher, onDestroy } from "svelte";
  import { theme } from "$lib/store/theme.js";
  import { colors } from "$lib/store/colors.js";
  import { get } from "svelte/store";
  import { mailsStore } from "$lib/store/mails-store";
  const dispatch = createEventDispatcher();

  let to = replyData?.to || "";
  let subject = replyData?.subject || "";
  let body = replyData?.body || "";
  let attachmentFile = null;
  let attachmentBlob = null;

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
  

  onDestroy(() => unsubscribeTheme());


  async function handleSendReply() {
  let attachmentIds = [];
    if (attachmentBlob) {
    const base64String = await blobToBase64(attachmentBlob);
    attachmentIds = [base64String];
  }

   const mail = {
      to,
      subject,
      body,
      isReply: true,
      parentMailId: [replyData.parentMailId],
      attachmentIds,
    };

  

  const response = await mailsStore.sendEmails(mail);
  console.log(response,'response')

  to = "";
  subject = "";
  body = "";
  attachmentFile = null;
  attachmentBlob = null;
    dispatch("close");
}

function handleAttachmentUpload(event) {
  const file = event.target.files[0];
  if (file) {
    attachmentFile = file;
    const reader = new FileReader();
    reader.onloadend = () => {
      attachmentBlob = new Blob([reader.result], { type: file.type });
    };
    reader.readAsArrayBuffer(file);
  }
}


function blobToBase64(blob) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onloadend = () => {
      const base64String = reader.result.split(',')[1]; 
      resolve(base64String);
    };
    reader.onerror = reject;
    reader.readAsDataURL(blob);
  });
}
</script>

<div class="fixed inset-0 backdrop-blur-sm bg-white/30 flex items-center justify-center z-50">

  <div
    class="p-6 rounded-lg w-full max-w-xl shadow-xl transition-colors duration-300"
    style="background-color: {currentColors.cardBg}; color: {currentColors.color};"
  >
    <h2 class="text-xl font-bold mb-4">Reply to Email</h2>

    <form on:submit|preventDefault={handleSendReply} class="space-y-4">
      <input
        bind:value={to}
        readonly
        class="w-full border px-3 py-2 rounded"
        style="background-color: {currentColors.inputBg}; color: {currentColors.inputText}; border-color: {currentColors.border};"
      />

      <input
        bind:value={subject}
        readonly
        class="w-full border px-3 py-2 rounded"
        style="background-color: {currentColors.inputBg}; color: {currentColors.inputText}; border-color: {currentColors.border};"
      />

      <textarea
        bind:value={body}
        rows="6"
        class="w-full border px-3 py-2 rounded"
        style="background-color: {currentColors.inputBg}; color: {currentColors.inputText}; border-color: {currentColors.border};"
      ></textarea>

      <input
        type="file"
        on:change={handleAttachmentUpload}
        class="rounded"
        style="color: {currentColors.inputText};"
      />

      <div class="flex justify-between items-center mt-4">
        <button
          type="button"
          on:click={() => dispatch("close")}
          class="px-4 py-2 rounded hover:opacity-80"
          style="background-color: {currentColors.btn}; color: {currentColors.color};"
        >
          Cancel
        </button>
        <button
          type="submit"
          class="px-4 py-2 rounded hover:opacity-80"
          style="background-color: {currentColors.btn}; color: white;"
        >
          Send Reply
        </button>
      </div>
    </form>
  </div>
</div>

