<script setup lang="ts">
import { computed } from 'vue'

type ObjetivosGrupo = {
  total?: number
  no_iniciado?: number
  en_progreso?: number
  finalizado?: number
  avance?: number
}

const props = withDefaults(
  defineProps<{
    objetivos?: ObjetivosGrupo | null
    titulo?: string
    compacto?: boolean
  }>(),
  {
    objetivos: null,
    titulo: 'Objetivos',
    compacto: false,
  },
)

const datos = computed(() => {
  const o = props.objetivos || {}
  const total = Number(o.total || 0)
  const noIniciado = Number(o.no_iniciado || 0)
  const enProgreso = Number(o.en_progreso || 0)
  const finalizado = Number(o.finalizado || 0)
  const avance = Number(o.avance || 0)
  const pct = (n: number) => (total > 0 ? Math.round((n / total) * 100) : 0)
  return {
    total,
    noIniciado,
    enProgreso,
    finalizado,
    avance,
    pctNoIniciado: pct(noIniciado),
    pctEnProgreso: pct(enProgreso),
    pctFinalizado: pct(finalizado),
  }
})
</script>

<template>
  <div v-if="datos.total > 0" class="obj-grupo" :class="{ 'obj-grupo-compacto': compacto }">
    <div class="obj-grupo-head">
      <span class="obj-grupo-titulo">{{ titulo }}</span>
      <span class="obj-grupo-avance">Avance: {{ datos.avance }}%</span>
    </div>
    <div class="obj-grupo-bar" :title="`${datos.noIniciado} no iniciados, ${datos.enProgreso} en progreso, ${datos.finalizado} finalizados`">
      <div class="obj-grupo-seg seg-noiniciado" :style="{ width: `${datos.pctNoIniciado}%` }" />
      <div class="obj-grupo-seg seg-progreso" :style="{ width: `${datos.pctEnProgreso}%` }" />
      <div class="obj-grupo-seg seg-finalizado" :style="{ width: `${datos.pctFinalizado}%` }" />
    </div>
    <div class="obj-grupo-stats">
      <div class="obj-grupo-stat">
        <span class="obj-grupo-stat-val">{{ datos.total }}</span>
        <span class="obj-grupo-stat-lbl">Total</span>
      </div>
      <div class="obj-grupo-stat">
        <span class="obj-grupo-stat-val obj-noiniciado">{{ datos.noIniciado }}</span>
        <span class="obj-grupo-stat-lbl">No iniciados ({{ datos.pctNoIniciado }}%)</span>
      </div>
      <div class="obj-grupo-stat">
        <span class="obj-grupo-stat-val obj-progreso">{{ datos.enProgreso }}</span>
        <span class="obj-grupo-stat-lbl">En progreso ({{ datos.pctEnProgreso }}%)</span>
      </div>
      <div class="obj-grupo-stat">
        <span class="obj-grupo-stat-val obj-finalizado">{{ datos.finalizado }}</span>
        <span class="obj-grupo-stat-lbl">Finalizados ({{ datos.pctFinalizado }}%)</span>
      </div>
    </div>
  </div>
</template>

<style scoped>
.obj-grupo {
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  padding: 0.85rem 1rem;
  background: linear-gradient(135deg, #ffffff 0%, #f8fafc 100%);
  display: flex;
  flex-direction: column;
  gap: 0.6rem;
}
.obj-grupo-head {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 0.75rem;
}
.obj-grupo-titulo {
  font-weight: 700;
  color: #0f172a;
  font-size: 0.92rem;
}
.obj-grupo-avance {
  display: inline-flex;
  align-items: center;
  padding: 0.25rem 0.65rem;
  border-radius: 999px;
  background: #ede9fe;
  color: #6d28d9;
  font-weight: 700;
  font-size: 0.8rem;
  white-space: nowrap;
}
.obj-grupo-bar {
  display: flex;
  width: 100%;
  height: 12px;
  border-radius: 999px;
  overflow: hidden;
  background: #f1f5f9;
}
.obj-grupo-seg {
  height: 100%;
  transition: width 0.4s ease;
}
.seg-noiniciado { background: #94a3b8; }
.seg-progreso { background: #f59e0b; }
.seg-finalizado { background: #16a34a; }
.obj-grupo-stats {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 0.6rem;
}
.obj-grupo-stat {
  display: flex;
  flex-direction: column;
  gap: 0.1rem;
}
.obj-grupo-stat-val {
  font-size: 1.25rem;
  font-weight: 700;
  color: #0f172a;
  line-height: 1;
}
.obj-grupo-stat-val.obj-noiniciado { color: #475569; }
.obj-grupo-stat-val.obj-progreso { color: #a16207; }
.obj-grupo-stat-val.obj-finalizado { color: #15803d; }
.obj-grupo-stat-lbl {
  font-size: 0.74rem;
  color: #64748b;
}
.obj-grupo-compacto .obj-grupo-stat-val { font-size: 1.05rem; }
@media (max-width: 640px) {
  .obj-grupo-stats { grid-template-columns: repeat(2, minmax(0, 1fr)); }
}
</style>
