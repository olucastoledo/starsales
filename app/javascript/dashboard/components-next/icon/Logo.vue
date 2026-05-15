<script setup>
import { useAttrs } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';

const attrs = useAttrs();
const globalConfig = useMapGetter('globalConfig/get');
</script>

<template>
  <img
    v-if="globalConfig.logoThumbnail"
    v-bind="attrs"
    :src="globalConfig.logoThumbnail"
  />
  <svg
    v-else
    v-once
    v-bind="attrs"
    width="16"
    height="16"
    viewBox="0 0 16 16"
    fill="none"
    xmlns="http://www.w3.org/2000/svg"
  >
    <defs>
      <linearGradient id="ss-logo-grad" x1="0" y1="0" x2="1" y2="1">
        <stop offset="0%" stop-color="#075E54"/>
        <stop offset="100%" stop-color="#25D366"/>
      </linearGradient>
    </defs>
    <rect width="16" height="16" rx="3.5" fill="url(#ss-logo-grad)"/>
    <polygon points="12.5,1.5 13,2.8 14.4,2.8 13.3,3.6 13.7,4.9 12.5,4.1 11.3,4.9 11.7,3.6 10.6,2.8 12,2.8" fill="rgba(255,255,255,0.5)"/>
    <text x="8" y="12.5" font-family="Arial Black,Arial,sans-serif" font-weight="900" font-size="8.5" text-anchor="middle" fill="white" letter-spacing="-0.5">SS</text>
  </svg>
</template>
