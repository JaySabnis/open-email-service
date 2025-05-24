<script>
  import { onMount, onDestroy } from 'svelte';
  import { goto } from '$app/navigation';

  let profile;

  function updateProfileFromStorage() {
    const cached = JSON.parse(localStorage.getItem('userProfileCache'));
    profile = cached?.data || null;
  }

  onMount(() => {
    updateProfileFromStorage();
    window.addEventListener('profileUpdated', updateProfileFromStorage);
  });

  onDestroy(() => {
    window.removeEventListener('profileUpdated', updateProfileFromStorage);
  });

  function goToProfile() {
    goto('/profile');
  }
</script>

<nav class="bg-blue-600 h-12 md:h-14 px-4 flex items-center justify-end shadow-md">
  <button
    on:click={goToProfile}
    class="focus:outline-none rounded-full overflow-hidden border-2 border-white w-10 h-10"
    aria-label="Go to Profile"
  >
    {#if profile?.profileImage}
      <img
        src={profile?.profileImage}
        alt="User Profile"
        class="w-full h-full object-cover cursor-pointer"
      />
    {:else}
      <div class="bg-gray-300 w-full h-full flex items-center justify-center text-blue-600 font-bold">
        U
      </div>
    {/if}
  </button>
</nav>
