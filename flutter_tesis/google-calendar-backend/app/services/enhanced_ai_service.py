"""
Servicio Enhanced AI que combina análisis estadístico y Groq
"""
from typing import List, Dict, Any
from datetime import datetime
try:
    from ..ai_external.groq_service import GroqService
    GROQ_AVAILABLE = True
except Exception as e:
    print(f"⚠️ Groq no disponible: {e}")
    GROQ_AVAILABLE = False

class EnhancedAIService:
    def __init__(self):
        self.groq_service = GroqService() if GROQ_AVAILABLE else None
        
    def initialize_with_data(self, events_data: List[Dict[str, Any]]):
        """
        Inicializa el sistema con datos históricos del usuario
        """
        print("🤖 Inicializando sistema Enhanced AI...")
        print(f"✅ Sistema listo con {len(events_data)} eventos")
    
    def analyze_user_calendar(self, events_data: List[Dict[str, Any]]) -> Dict[str, Any]:
        """
        Análisis completo del calendario combinando estadísticas y Groq
        """
        try:
            # 1. Análisis estadístico simple
            insights = self._get_simple_insights(events_data)
            print(f"📊 Insights generados: {len(insights)} métricas")
            
            # 2. Interpretación con Groq si está disponible
            if self.groq_service:
                groq_analysis = self.groq_service.analyze_calendar_with_ml(insights, events_data)
                ai_text = groq_analysis.get("analysis", "No disponible")
                model = groq_analysis.get("model_used", "groq")
            else:
                ai_text = self._generate_simple_analysis(insights)
                model = "estadisticas"
            
            return {
                "success": True,
                "ml_insights": insights,
                "ai_analysis": ai_text,
                "model_info": model,
                "total_events_analyzed": len(events_data),
                "timestamp": datetime.now().isoformat()
            }
            
        except Exception as e:
            print(f"❌ Error en análisis completo: {e}")
            return {
                "success": False,
                "error": str(e),
                "ml_insights": {},
                "ai_analysis": "Error en el análisis"
            }
    
    def _get_simple_insights(self, events_data: List[Dict[str, Any]]) -> Dict[str, Any]:
        """Genera insights estadísticos simples"""
        if not events_data:
            return {}
        
        total_events = len(events_data)
        durations = []
        types = {}
        hours = []
        
        for event in events_data:
            # Calcular duración
            try:
                start = datetime.fromisoformat(str(event.get('date', '')).replace('Z', '+00:00'))
                end = datetime.fromisoformat(str(event.get('end_time', '')).replace('Z', '+00:00'))
                duration = (end - start).total_seconds() / 60
                durations.append(duration)
                hours.append(start.hour)
            except:
                continue
            
            # Contar tipos
            event_type = event.get('type', 'otro')
            types[event_type] = types.get(event_type, 0) + 1
        
        avg_duration = sum(durations) / len(durations) if durations else 0
        most_common_hour = max(set(hours), key=hours.count) if hours else 10
        
        return {
            'total_events': total_events,
            'avg_duration': avg_duration,
            'best_hour': most_common_hour,
            'event_types': types,
            'avg_productivity': 0.7  # Valor por defecto
        }
    
    def _generate_simple_analysis(self, insights: Dict[str, Any]) -> str:
        """Genera un análisis textual simple"""
        total = insights.get('total_events', 0)
        avg_dur = insights.get('avg_duration', 0)
        best_hour = insights.get('best_hour', 10)
        
        return f"""📊 Análisis de tu calendario:

• Tienes {total} eventos programados
• Duración promedio: {avg_dur:.0f} minutos
• Tu hora más productiva: {best_hour}:00h

💡 Recomendaciones:
• Mantén bloques de tiempo enfocado
• Considera agregar descansos entre eventos
• Organiza tareas importantes en tu hora pico"""
    
    def chat_with_ai(self, user_message: str, events_context: List[Dict[str, Any]] = None) -> Dict[str, Any]:
        """
        Chat inteligente que usa contexto para respuestas personalizadas
        """
        try:
            # Preparar contexto con insights
            context = {}
            if events_context:
                insights = self._get_simple_insights(events_context)
                context = {
                    "ml_insights": insights,
                    "events": events_context[:5],  # Solo eventos recientes
                    "current_date": datetime.now().strftime("%Y-%m-%d %H:%M")
                }
            
            # Chat con Groq si está disponible
            if self.groq_service:
                response = self.groq_service.chat_with_assistant(user_message, context)
            else:
                response = {
                    "response": f"Recibí tu mensaje: '{user_message}'. Enhanced AI simplificado está activo.",
                    "model_used": "simple"
                }
            
            return {
                "success": True,
                "user_message": user_message,
                "ai_response": response.get("response", "No disponible"),
                "model_used": response.get("model_used", "simple"),
                "context_used": bool(context),
                "timestamp": datetime.now().isoformat()
            }
            
        except Exception as e:
            print(f"❌ Error en chat IA: {e}")
            return {
                "success": False,
                "error": str(e),
                "user_message": user_message,
                "ai_response": "Lo siento, ocurrió un error. Inténtalo de nuevo."
            }
    
    def generate_smart_event(self, partial_event: Dict[str, Any], user_history: List[Dict[str, Any]] = None) -> Dict[str, Any]:
        """
        Genera contenido inteligente para eventos
        """
        try:
            # Generar contenido simple
            enhanced_event = partial_event.copy()
            
            if self.groq_service:
                groq_result = self.groq_service.generate_event_content(enhanced_event)
                content = groq_result.get("generated_content", {})
                model = groq_result.get("model_used", "groq")
            else:
                content = {"description": f"Evento: {partial_event.get('title', 'Sin título')}"}
                model = "simple"
            
            result = {
                "success": True,
                "original_event": partial_event,
                "generated_content": content,
                "ai_model": model,
                "enhanced": True
            }
            
            return result
            
        except Exception as e:
            print(f"❌ Error generando evento inteligente: {e}")
            return {
                "success": False,
                "error": str(e),
                "original_event": partial_event,
                "generated_content": {"description": "Error generando contenido"}
            }
    
    def create_intelligent_study_plan(self, subject: str, exam_date: str, available_calendar: List[Dict[str, Any]]) -> Dict[str, Any]:
        """
        Crea plan de estudio simple sin ML
        """
        try:
            # Horarios productivos típicos
            productive_hours = [9, 10, 11, 14, 15, 16, 19, 20]
            optimal_slots = [
                {
                    "day": day,
                    "hour": hour,
                    "duration": 90,
                    "type": "estudio"
                }
                for day in range(5)  # Lunes a viernes
                for hour in productive_hours
            ][:8]  # Top 8 slots
            
            # Plan simple
            study_plan = f"""Plan de estudio para {subject} (Examen: {exam_date}):

1. Sesiones diarias de 90 minutos
2. Horarios recomendados: 9-11h, 14-16h, 19-20h
3. Incluir descansos de 10 minutos cada hora
4. Revisar material al final de cada día

Slots óptimos: {len(optimal_slots)} sesiones disponibles"""
            
            return {
                "success": True,
                "subject": subject,
                "exam_date": exam_date,
                "ai_study_plan": study_plan,
                "optimal_slots_count": len(optimal_slots),
                "model_used": "simple"
            }
            
        except Exception as e:
            print(f"❌ Error creando plan de estudio: {e}")
            return {
                "success": False,
                "error": str(e),
                "subject": subject,
                "ai_study_plan": "Error creando el plan"
            }
    
    def predict_schedule_optimization(self, current_week_events: List[Dict[str, Any]]) -> Dict[str, Any]:
        """
        Predice optimizaciones simples para la semana
        """
        try:
            if not current_week_events:
                return {"success": False, "message": "No hay eventos para analizar"}
            
            # Análisis simple
            insights = self._get_simple_insights(current_week_events)
            
            # Detectar problemas
            issues = []
            recommendations = []
            
            total_events = insights.get('total_events', 0)
            if total_events > 30:
                issues.append("Calendario muy cargado")
                recommendations.append("Considerar eliminar eventos no prioritarios")
            
            if total_events < 5:
                issues.append("Calendario poco estructurado")
                recommendations.append("Agregar más eventos de estudio y ejercicio")
            
            return {
                "success": True,
                "week_analysis": insights,
                "detected_issues": issues,
                "ml_recommendations": recommendations,
                "optimization_score": 0.7,
                "analysis_date": datetime.now().isoformat()
            }
            
        except Exception as e:
            print(f"❌ Error en predicción de optimización: {e}")
            return {
                "success": False,
                "error": str(e)
            }
    
    def get_system_status(self) -> Dict[str, Any]:
        """
        Retorna estado del sistema simplificado
        """
        return {
            "ml_models_trained": False,
            "groq_available": self.groq_service is not None,
            "system_ready": True,
            "capabilities": [
                "Análisis estadístico de patrones",
                "Chat inteligente con Groq",
                "Generación de contenido",
                "Planes de estudio básicos"
            ]
        }