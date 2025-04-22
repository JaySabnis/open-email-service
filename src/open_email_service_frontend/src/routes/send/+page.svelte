<script>
  import { mailsStore } from "$lib/store/mails-store";

  let to = "";
  let subject = "";
  let body = "";

  async function handleSendMail() {
    const mail = {to, subject, body};
    const mailResponse = await mailsStore.sendEmails(mail);
    to = "";
    subject = "";
    body = "";
    //   console.log(mailResponse,{
    //     to,
    //     subject,
    //     body
    //   }, "mail");
  }
</script>

<div class="max-w-xl mx-auto p-6 mt-10 bg-white shadow-lg rounded-lg">
  <h1 class="text-2xl font-semibold mb-6 text-center">Send Email</h1>

  <form on:submit|preventDefault={handleSendMail} class="space-y-6">
    <div>
      <label for="to" class="block text-sm font-medium mb-1">To</label>
      <input
        id="to"
        bind:value={to}
        class="w-full border px-3 py-2 rounded-md focus:outline-none focus:ring focus:border-blue-300"
        placeholder="recipient@example.com"
        required
      />
    </div>

    <div>
      <label for="subject" class="block text-sm font-medium mb-1">Subject</label
      >
      <input
        id="subject"
        type="text"
        bind:value={subject}
        class="w-full border px-3 py-2 rounded-md focus:outline-none focus:ring focus:border-blue-300"
        placeholder="Email subject"
        required
      />
    </div>

    <div>
      <label for="body" class="block text-sm font-medium mb-1">Body</label>
      <textarea
        id="body"
        rows="5"
        bind:value={body}
        class="w-full border px-3 py-2 rounded-md focus:outline-none focus:ring focus:border-blue-300"
        placeholder="Write your message here..."
        required
      ></textarea>
    </div>

    <div class="text-center">
      <button
        type="submit"
        class="bg-blue-600 text-white px-6 py-2 rounded-md hover:bg-blue-700 transition"
      >
        Send Email
      </button>
    </div>
  </form>
</div>
