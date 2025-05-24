<script>
  import { signOut } from "$lib/services/auth.services";
  import { authSignedInStore } from "$lib/derived/auth.derived";
  import InboxComponent from '../../lib/components/inbox.svelte';
  import { theme } from '$lib/store/theme.js';
  import { colors } from '$lib/store/colors.js';
  import { onDestroy } from 'svelte';
  import { get } from 'svelte/store';
  
  if(!authSignedInStore){
    signOut();
  }

  let currentTheme = 'light';
  let currentColors = colors.light;
  let btnBgColor = currentColors?.btn;


  const unsubscribeTheme = theme.subscribe(value => {
    currentTheme = value;
    const colorsValue = get(colors);
    currentColors = colorsValue[currentTheme];

     btnBgColor = currentColors.btn; 
     
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

  function handleMouseEnter() {
    btnBgColor = currentColors.btnHover;
  }

  function handleMouseLeave() {
    btnBgColor = currentColors.btn;
  }

</script>

<main>
  <!-- <div class="flex justify-end mb-4 p-4">
    <a
      href="/send"
      class="font-semibold py-2 px-4 rounded shadow transition"
      style="background-color: {btnBgColor}; color: {currentColors.btnText};"
      on:mouseenter={handleMouseEnter}
      on:mouseleave={handleMouseLeave}
    >
      Send Email
    </a>
  </div> -->

  <InboxComponent />
</main>
