<script>
  import { theme } from '$lib/store/theme.js';
  import { colors } from '$lib/store/colors.js';
  import { onDestroy } from 'svelte';
  import { get } from 'svelte/store';
  export let message = "Loading...";
  export let fullScreen = true;

  let currentTheme = 'light';
  let currentColors = colors.light;

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
  onDestroy(() => {
    unsubscribeTheme();
  });
</script>

<style>
  .spinner {
    width: 4rem;
    height: 4rem;
    border-width: 4px;
    border-style: solid;
    border-radius: 9999px;
    border-top-color: transparent;
    animation: spin 1s linear infinite;
  }

  @keyframes spin {
    to {
      transform: rotate(360deg);
    }
  }

  .pulse {
    animation: pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite;
  }

  @keyframes pulse {
    0%, 100% {
      opacity: 1;
    }
    50% {
      opacity: 0.5;
    }
  }
</style>

<div class="flex items-center justify-center" style="height: {fullScreen ? '100vh' : '100%'}; background-color: {currentColors.bgLightColor};">
  <div class="flex flex-col items-center space-y-4">
    <div
      class="spinner"
      style="border-color: {currentColors.btn}; border-top-color: transparent;"
    ></div>
    <p class="pulse" style="color: {currentColors.btn}; font-weight: 500; font-size: 1.125rem;">
      {message}
    </p>
  </div>
</div>
