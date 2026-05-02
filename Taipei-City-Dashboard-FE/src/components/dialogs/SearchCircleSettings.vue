<!-- Developed by Taipei Urban Intelligence Center 2023-2024-->

<script setup>
import { computed, ref, watch } from "vue";
import { useMapStore } from "../../store/mapStore";
import { useDialogStore } from "../../store/dialogStore";

import DialogContainer from "./DialogContainer.vue";
import CustomCheckBox from "../utilities/forms/CustomCheckBox.vue";

const mapStore = useMapStore();
const dialogStore = useDialogStore();

const radiusKm = ref(mapStore.searchCircleRadiusKm || 1.2);
const selectedLayerIds = ref([]);

const estimatedWalkMinutes = computed(() => Math.round((Number(radiusKm.value) / 4.8) * 60));

const availablePointLayers = computed(() =>
	mapStore.currentVisibleLayers
		.filter((layerId) => ["circle", "symbol"].includes(layerId.split("-")[1]))
		.map((layerId) => ({
			id: layerId,
			title:
				mapStore.mapConfigs[layerId]?.title ||
				mapStore.mapConfigs[layerId]?.index ||
				layerId,
		})),
);

watch(
	availablePointLayers,
	(layers) => {
		const availableIds = layers.map((layer) => layer.id);
		selectedLayerIds.value = selectedLayerIds.value.filter((layerId) =>
			availableIds.includes(layerId),
		);
		if (selectedLayerIds.value.length === 0) {
			selectedLayerIds.value = [...availableIds];
		}
	},
	{ immediate: true },
);

function handleClose() {
	dialogStore.hideAllDialogs();
}

function handleStart() {
	const parsedRadiusKm = Number(radiusKm.value);
	if (!Number.isFinite(parsedRadiusKm) || parsedRadiusKm <= 0) {
		dialogStore.showNotification("fail", "請輸入大於 0 的搜尋半徑");
		return;
	}
	if (selectedLayerIds.value.length === 0) {
		dialogStore.showNotification("fail", "請至少選擇一個點位組件");
		return;
	}

	mapStore.enableSearchCircleClickMode({
		radiusKm: parsedRadiusKm,
		layerIds: selectedLayerIds.value,
	});
	dialogStore.hideAllDialogs();
}
</script>

<template>
  <DialogContainer
    dialog="searchCircleSettings"
    @on-close="handleClose"
  >
    <div class="searchcirclesettings">
      <h2>搜尋圈設定</h2>
      <div class="searchcirclesettings-input">
        <div class="searchcirclesettings-radiusheader">
          <label for="search-circle-radius">搜尋半徑</label>
          <strong>{{ Number(radiusKm).toFixed(1) }} km</strong>
        </div>
        <div class="searchcirclesettings-slider">
          <span>0.1</span>
          <input
            id="search-circle-radius"
            v-model="radiusKm"
            type="range"
            min="0.1"
            max="5"
            step="0.1"
          >
          <span>5 km</span>
        </div>
        <p class="searchcirclesettings-walktime">
          約 {{ estimatedWalkMinutes }} 分鐘步行路程
        </p>
        <p class="searchcirclesettings-note">
          設定後點擊地圖，系統會統計圓圈內的點位資料。
        </p>

        <label>統計資料來源</label>
        <div
          v-if="availablePointLayers.length > 0"
          class="searchcirclesettings-layers"
        >
          <div
            v-for="layer in availablePointLayers"
            :key="layer.id"
          >
            <input
              :id="`search-circle-${layer.id}`"
              v-model="selectedLayerIds"
              type="checkbox"
              :value="layer.id"
              class="custom-check-input"
            >
            <CustomCheckBox :for="`search-circle-${layer.id}`">
              {{ layer.title }}
            </CustomCheckBox>
          </div>
        </div>
      </div>
      <div class="searchcirclesettings-control">
        <button @click="handleClose">
          取消
        </button>
        <button @click="handleStart">
          開始圈選
        </button>
      </div>
    </div>
  </DialogContainer>
</template>

<style scoped lang="scss">
.searchcirclesettings {
	width: 320px;

	&-input {
		display: flex;
		flex-direction: column;

		label {
			margin: 8px 0;
			font-size: var(--font-s);
			color: var(--color-complement-text);
		}

		input[type="checkbox"] {
			display: none;

			& + label {
				font-size: var(--font-ms);
			}

			&:checked + label {
				color: white;
			}

			&:hover + label {
				color: var(--color-highlight);
			}
		}
	}

	&-radiusheader {
		display: flex;
		align-items: center;
		justify-content: space-between;

		strong {
			color: var(--color-highlight);
			font-size: var(--font-ms);
		}
	}

	&-slider {
		display: grid;
		grid-template-columns: auto 1fr auto;
		align-items: center;
		gap: 8px;
		margin: 2px 0 4px;
		color: var(--color-complement-text);
		font-size: var(--font-s);

		input[type="range"] {
			width: 100%;
			accent-color: var(--color-highlight);
			cursor: pointer;
		}
	}

	&-walktime {
		margin: 2px 0 8px;
		color: white;
		font-size: var(--font-ms);
	}

	&-layers {
		max-height: 120px;
		overflow-y: auto;

		&::-webkit-scrollbar {
			width: 4px;
		}

		&::-webkit-scrollbar-thumb {
			border-radius: 4px;
			background-color: rgba(136, 135, 135, 0.5);
		}
	}

	&-note {
		margin: 4px 0 8px;
		color: var(--color-complement-text);
		font-size: var(--font-s);
		line-height: 1.4;
	}

	&-control {
		height: var(--font-xl);
		display: flex;
		justify-content: flex-end;
		gap: 8px;
		margin-top: 12px;

		button {
			padding: 2px 8px;
			border-radius: 5px;
			background-color: var(--color-highlight);
			transition: opacity 0.2s;

			&:first-child {
				background-color: var(--color-border);
			}

			&:hover {
				opacity: 0.8;
			}
		}
	}
}
</style>
