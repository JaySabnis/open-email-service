<script>
  import { onMount, onDestroy } from 'svelte';
  import { goto } from '$app/navigation';
  import { theme } from '$lib/store/theme';
  import { colors } from '$lib/store/colors';
  import { get } from 'svelte/store';

  let profile = null;
  let currentTheme;
  let currentColors;
  let profileImageUrl = '';

  const unsubscribeTheme = theme.subscribe(value => {
    currentTheme = value;
    const colorsValue = get(colors);
    currentColors = colorsValue[currentTheme];
  });

  function updateProfileFromStorage() {
    try {
      const cached = JSON.parse(localStorage.getItem('userProfileCache'));
      if (cached) {
        profile = cached.data || null;
        profileImageUrl = cached.data?.profileImage || 
                         cached.data?.profileImage || 
                         '';
      }
    } catch (error) {
      console.error('Error reading profile from localStorage:', error);
    }
  }

  onMount(() => {
    updateProfileFromStorage();
    window.addEventListener('profileUpdated', updateProfileFromStorage);
    window.addEventListener('storage', handleStorageEvent);
  });

  onDestroy(() => {
    window.removeEventListener('profileUpdated', updateProfileFromStorage);
    window.removeEventListener('storage', handleStorageEvent);
    unsubscribeTheme();
  });

  function handleStorageEvent(event) {
    if (event.key === 'userProfileCache') {
      updateProfileFromStorage();
    }
  }

  function goToProfile() {
    goto('/profile');
  }

  function toggleTheme() {
    theme.set(currentTheme === 'light' ? 'dark' : 'light');
  }
</script>

<nav class="h-12 md:h-14 px-4 flex items-center justify-end shadow-md" 
     style="background-color: {currentColors?.navbar || currentColors?.bgColor}; 
            color: {currentColors?.color};">
  
  <button
    on:click={toggleTheme}
    aria-label="Toggle theme"
    class="mr-4 px-3 py-1 rounded transition hover:opacity-80"
    style="background-color: {currentColors?.btnSecondary || 'transparent'}; 
           color: {currentColors?.color};"
  >
    {#if currentTheme === 'light'}
      🌙 Dark Mode
    {:else}
      ☀️ Light Mode
    {/if}
  </button>

  <button
    on:click={goToProfile}
    class="focus:outline-none rounded-full overflow-hidden border-2 w-10 h-10 transition hover:opacity-80"
    style="border-color: {currentColors?.accent || 'white'};"
    aria-label="Go to Profile"
  >
    {#if profileImageUrl}
      <img
        src={profileImageUrl}
        alt="User Profile"
        class="w-full h-full object-cover cursor-pointer"
      />
    {:else}
      <div class="w-full h-full flex items-center justify-center font-bold"
           style="background-color: {currentColors?.btnSecondary || '#E5E7EB'}; 
                  color: {currentColors?.btn || '#8C6AED'};">
        {profile?.name?.[0]?.toUpperCase() || 'U'}
      </div>
    {/if}
  </button>
</nav>