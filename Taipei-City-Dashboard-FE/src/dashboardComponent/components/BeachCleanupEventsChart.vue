<script setup>
import { computed, ref, watch } from "vue";

const props = defineProps([
	"chart_config",
	"activeChart",
	"series",
	"map_config",
	"map_filter",
	"map_filter_on",
]);

const selectedIndex = ref(0);

const events = computed(() => {
	return (props.series || [])
		.map((item) => {
			const parts = String(item.icon || "").split("｜");
			const isLegacyPayload = parts.length === 5;
			const city = parts[0] || "雙北";
			const startTime = parts[1] || "時間未提供";
			const location = parts[2] || "地點未提供";
			const rendezvous = isLegacyPayload ? location : parts[3] || location;
			const organizer = isLegacyPayload ? parts[3] : parts[4];
			const url = isLegacyPayload ? parts[4] : parts[5];

			return {
				name: item.name,
				daysUntil: Number(item.data?.[0] ?? 0),
				city,
				startTime,
				location,
				rendezvous: rendezvous || "集合點未提供",
				organizer: organizer || "主辦單位未提供",
				url: url || "",
				locationUrl: isUrl(location) ? location : "",
				dayKey: startTime.slice(0, 10),
				timeKey: startTime.slice(11, 16),
			};
		})
		.sort((a, b) => a.daysUntil - b.daysUntil);
});

const selectedEvent = computed(() => events.value[selectedIndex.value] || events.value[0]);

function isUrl(value) {
	return /^https?:\/\//.test(String(value || ""));
}

function dayText(days) {
	if (days <= 0) {
		return "今天";
	}
	if (days === 1) {
		return "明天";
	}
	return `${days}天後`;
}

function monthDay(value) {
	if (!value || value === "時間未提供") {
		return "--/--";
	}
	return value.slice(5, 10).replace("-", "/");
}

function selectEvent(index) {
	selectedIndex.value = index;
}

watch(events, (currentEvents) => {
	if (selectedIndex.value >= currentEvents.length) {
		selectedIndex.value = 0;
	}
});
</script>

<template>
  <div
    v-if="activeChart === 'BeachCleanupEventsChart'"
    class="beachCleanupEvents"
  >
    <div
      v-if="events.length === 0"
      class="beachCleanupEvents-empty"
    >
      <span>water_drop</span>
      <strong>目前雙北沒有可參與的淨灘活動</strong>
      <p>平台會定期更新，之後有新活動會自動顯示在這裡。</p>
    </div>

    <template v-else>
      <section class="beachCleanupEvents-hero">
        <div>
          <p class="beachCleanupEvents-eyebrow">
            選取活動
          </p>
          <h4>{{ selectedEvent.name }}</h4>
          <p class="beachCleanupEvents-heroMeta">
            {{ selectedEvent.city }} · {{ selectedEvent.startTime }}
          </p>
          <div class="beachCleanupEvents-heroDetails">
            <span class="material-icons">place</span>
            <a
              v-if="selectedEvent.locationUrl"
              :href="selectedEvent.locationUrl"
              target="_blank"
              rel="noreferrer noopener"
            >
              查看地點地圖
            </a>
            <span v-else>{{ selectedEvent.location }}</span>
            <span class="material-icons">flag</span>
            <span>集合：{{ selectedEvent.rendezvous }}</span>
            <span class="material-icons">groups</span>
            <span>{{ selectedEvent.organizer }}</span>
          </div>
        </div>
        <a
          class="beachCleanupEvents-heroAction"
          :href="selectedEvent.url"
          target="_blank"
          rel="noreferrer noopener"
        >
          報名
        </a>
      </section>

      <section class="beachCleanupEvents-list">
        <article
          v-for="(event, index) in events"
          :key="event.name + event.startTime"
          role="button"
          tabindex="0"
          class="beachCleanupEvents-card"
          :class="{
            urgent: event.daysUntil <= 3,
            active: index === selectedIndex,
          }"
          :aria-pressed="index === selectedIndex"
          @click="selectEvent(index)"
          @keydown.enter.prevent="selectEvent(index)"
          @keydown.space.prevent="selectEvent(index)"
        >
          <div class="beachCleanupEvents-date">
            <span>{{ dayText(event.daysUntil) }}</span>
          </div>

          <div class="beachCleanupEvents-content">
            <h5>{{ event.name }}</h5>
            <p>{{ monthDay(event.startTime) }} {{ event.timeKey }} · {{ event.organizer }}</p>
          </div>

          <span class="beachCleanupEvents-city">{{ event.city }}</span>

          <a
            class="beachCleanupEvents-link"
            :href="event.url"
            target="_blank"
            rel="noreferrer noopener"
            aria-label="前往活動報名頁"
            @click.stop
          >
            arrow_forward
          </a>
        </article>
      </section>
    </template>
  </div>
</template>

<style scoped lang="scss">
.beachCleanupEvents {
	position: relative;
	display: flex;
	flex-direction: column;
	gap: 0.6rem;
	height: 100%;
	min-height: 0;
	overflow-y: auto;
	overflow-x: hidden;
	padding: 0 0.2rem 0.15rem 0;
	color: var(--color-normal-text);

	&,
	* {
		box-sizing: border-box;
	}

	&::before {
		display: none;
	}

	&-empty {
		display: flex;
		flex-direction: column;
		align-items: center;
		justify-content: center;
		min-height: 100%;
		color: var(--color-complement-text);
		text-align: center;

		span {
			margin-bottom: 0.55rem;
			color: var(--color-highlight);
			font-family: var(--font-icon);
			font-size: 2rem;
		}

		strong {
			color: var(--color-normal-text);
			font-size: var(--font-m);
		}

		p {
			max-width: 18rem;
			margin-top: 0.4rem;
			font-size: var(--font-s);
			line-height: 1.5;
		}
	}

	&-hero {
		position: relative;
		display: grid;
		grid-template-columns: minmax(0, 1fr) auto;
		gap: 0.75rem;
		align-items: start;
		flex: 0 0 auto;
		padding: 0.75rem 0.85rem;
		overflow: hidden;
		border: 1px solid var(--color-border);
		border-radius: 10px;
		background:
			linear-gradient(135deg, rgba(92, 168, 216, 0.18), rgba(40, 42, 44, 0.5)),
			rgba(255, 255, 255, 0.03);

		h4 {
			margin: 0.1rem 0 0.25rem;
			overflow: hidden;
			font-size: var(--font-m);
			font-weight: 700;
			text-overflow: ellipsis;
			white-space: nowrap;
		}
	}

	&-eyebrow {
		margin: 0;
		color: var(--color-highlight);
		font-size: var(--font-s);
		font-weight: 700;
	}

	&-heroMeta {
		margin: 0;
		overflow: hidden;
		color: var(--color-complement-text);
		font-size: var(--font-s);
		text-overflow: ellipsis;
		white-space: nowrap;
	}

	&-heroDetails {
		display: grid;
		grid-template-columns: 0.95rem minmax(0, 1fr);
		gap: 0.12rem 0.3rem;
		max-height: 4rem;
		margin-top: 0.4rem;
		overflow: hidden;
		color: var(--color-complement-text);
		font-size: var(--font-s);
		line-height: 1.25;

		.material-icons {
			color: var(--color-highlight);
			font-size: 0.9rem;
		}

		a,
		span:not(.material-icons) {
			overflow: hidden;
			text-overflow: ellipsis;
			white-space: nowrap;
		}

		a {
			color: var(--color-highlight);
			text-decoration: none;
		}
	}

	&-heroAction {
		padding: 0.45rem 0.72rem;
		border-radius: 8px;
		background: var(--color-highlight);
		color: white;
		font-size: var(--font-s);
		font-weight: 700;
		text-decoration: none;
		white-space: nowrap;
	}

	&-list {
		display: flex;
		flex-direction: column;
		gap: 0.5rem;
		flex: 1 1 auto;
		min-height: 0;
		overflow-y: auto;
		padding-right: 0.15rem;
	}

	&-card {
		width: 100%;
		display: grid;
		grid-template-columns: 4.8rem minmax(0, 1fr) auto 1.7rem;
		gap: 0.55rem;
		align-items: center;
		flex: 0 0 auto;
		min-height: 3.65rem;
		padding: 0.5rem;
		overflow: visible;
		border: 1px solid var(--color-border);
		border-radius: 10px;
		background: rgba(255, 255, 255, 0.025);
		color: var(--color-normal-text);
		cursor: pointer;
		line-height: normal;
		outline: none;
		transition: transform 0.18s ease, border-color 0.18s ease, background 0.18s ease;

		&:hover {
			transform: translateY(-2px);
			border-color: rgba(92, 168, 216, 0.55);
			background: rgba(92, 168, 216, 0.08);
		}

		&.urgent {
			border-color: rgba(248, 207, 88, 0.35);
		}

		&.active {
			border-color: var(--color-highlight);
			background: rgba(92, 168, 216, 0.12);
		}

		&:focus-visible {
			border-color: var(--color-highlight);
			box-shadow: 0 0 0 2px rgba(92, 168, 216, 0.22);
		}
	}

	&-date {
		display: flex;
		align-items: center;
		justify-content: center;
		min-height: 2.35rem;
		border-radius: 8px;
		background: rgba(92, 168, 216, 0.12);
		overflow: hidden;

		span {
			max-width: 100%;
			color: var(--color-highlight);
			font-size: var(--font-s);
			font-weight: 700;
			line-height: 1.1;
			text-align: center;
			white-space: normal;
		}
	}

	&-content {
		min-width: 0;
		overflow: hidden;

		h5 {
			margin: 0;
			overflow: hidden;
			font-size: var(--font-ms);
			font-weight: 700;
			text-overflow: ellipsis;
			white-space: nowrap;
		}

		p {
			margin-top: 0.18rem;
			overflow: hidden;
			color: var(--color-complement-text);
			font-size: var(--font-s);
			text-overflow: ellipsis;
			white-space: nowrap;
		}
	}

	&-city {
		flex: 0 0 auto;
		padding: 0.12rem 0.42rem;
		border: 1px solid rgba(92, 168, 216, 0.45);
		border-radius: 999px;
		color: var(--color-highlight);
		font-size: var(--font-s);
		white-space: nowrap;
	}

	&-link {
		display: flex;
		align-items: center;
		justify-content: center;
		border-radius: 999px;
		color: var(--color-highlight);
		font-family: var(--font-icon);
		font-size: var(--font-ms);
		text-decoration: none;
		transition: background 0.18s ease;

		&:hover {
			background: rgba(92, 168, 216, 0.14);
		}
	}
}

@media (max-width: 520px) {
	.beachCleanupEvents {
		&-card {
			grid-template-columns: 4.3rem 1fr;
		}

		&-city {
			display: none;
		}

		&-link {
			display: none;
		}
	}
}
</style>
