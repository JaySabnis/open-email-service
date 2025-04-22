<script>
  import { signOut } from "$lib/services/auth.services";
  import { authSignedInStore } from "$lib/derived/auth.derived";
  import InboxComponent from '../../lib/components/inbox.svelte'

  if(!authSignedInStore){
    signOut();
  }
</script>

<main class="p-4">
  <div class="flex justify-end mb-4">
    <a
      href="/send"
      class="bg-blue-600 hover:bg-blue-700 text-white font-semibold py-2 px-4 rounded shadow transition"
    >
      Send Email
    </a>
  </div>

  <InboxComponent />
</main>