<script lang="ts">
  /** Tabbed code block with copy-to-clipboard */
  interface Tab {
    label: string;
    code: string;
  }

  let { tabs }: { tabs: Tab[] } = $props();
  let activeTab = $state(0);
  let copied = $state(false);

  function copyCode() {
    navigator.clipboard.writeText(tabs[activeTab].code);
    copied = true;
    setTimeout(() => (copied = false), 2000);
  }
</script>

<div class="code-block overflow-hidden">
  <!-- Tab bar -->
  <div class="flex border-b border-slate-700">
    {#each tabs as tab, i}
      <button
        class="px-4 py-2 text-sm font-mono transition-colors {activeTab === i
          ? 'text-amber-400 border-b-2 border-amber-400 bg-slate-800/50'
          : 'text-slate-400 hover:text-slate-200'}"
        onclick={() => (activeTab = i)}
      >
        {tab.label}
      </button>
    {/each}
    <div class="ml-auto flex items-center pr-3">
      <button
        class="text-xs font-mono text-slate-400 hover:text-emerald-400 transition-colors flex items-center gap-1"
        onclick={copyCode}
      >
        {#if copied}
          <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
          </svg>
          copied
        {:else}
          <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
              d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z" />
          </svg>
          copy
        {/if}
      </button>
    </div>
  </div>
  <!-- Code content -->
  <pre class="p-4 overflow-x-auto text-sm leading-relaxed"><code class="font-mono text-emerald-400">{tabs[activeTab].code}</code></pre>
</div>
