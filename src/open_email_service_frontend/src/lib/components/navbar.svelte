<script>
  import { signOut } from "$lib/services/auth.service";
  import { goto } from "$app/navigation";

  let menuOpen = false; 

  function toggleDropdown() {
    menuOpen = !menuOpen; 
  }

  async function handleSignOut() {
    await signOut();
    goto('/');
  }
</script>

<div class="relative">
  <nav class="bg-blue-600 p-4 flex justify-between items-center">
    <button class="text-white text-2xl font-semibold" on:click={goto('/dashboard')}>Open Email</button>

    <div class="relative">
      <button
        class="text-white focus:outline-none"
        on:click={toggleDropdown}
        aria-label="Menu"
      >
        {#if menuOpen}
          <div>X</div>
        {:else}
          <div class="w-2.5 h-0.5 bg-white mb-1.5"></div>
          <div class="w-2.5 h-0.5 bg-white mb-1.5"></div>
          <div class="w-2.5 h-0.5 bg-white"></div>
        {/if}
      </button>

      {#if menuOpen}
        <div
          id="dropdownMenu"
          class="absolute right-0 mt-2 w-40 bg-white shadow-md rounded-md"
        >
          <ul>
            <li>
              <a href="/profile" class="block px-4 py-2 text-gray-700 hover:bg-gray-200">Profile</a>
            </li>
            <li>
              <button on:click={handleSignOut} class="block px-4 py-2 text-gray-700 hover:bg-gray-200">Sign Out</button>
            </li>
          </ul>
        </div>
      {/if}
    </div>
  </nav>
</div>
