"""
Servicio Enhanced AI que combina Machine Learning y Groq
"""
from typing import List, Dict, Any
from datetime import datetime
from ..ml.ml_service import MLModels, MLDataProcessor
from ..ai_external.groq_service import GroqService

class EnhancedAIService:
    def __init__(self):
        self.ml_models = MLModels()
        self.groq_service = GroqService()
        self.ml_processor = MLDataProcessor()
        
    def initialize_with_data(self, events_data: List[Dict[str, Any]]):
        """
        Inicializa el sistema ML con datos históricos del usuario
        """
        print("🤖 Inicializando sistema ML+IA...")
        try:
            # Entrenar modelos ML
            self.ml_models.train_models(events_data)
            print(f"✅ Sistema ML entrenado con {len(events_data)} eventos")
        except Exception as e:
            print(f"⚠️  Error inicializando ML: {e}")
    
    def analyze_user_calendar(self, events_data: List[Dict[str, Any]]) -> Dict[str, Any]:
        """
        Análisis completo del calendario combinando ML y Groq
        """
        try:
            # 1. Análisis ML
            ml_insights = self.ml_models.get_schedule_insights(events_data)
            print(f"📊 ML insights generados: {len(ml_insights)} métricas")
            
            # 2. Interpretación con Groq
            groq_analysis = self.groq_service.analyze_calendar_with_ml(ml_insights, events_data)
            
            return {
                "success": True,
                "ml_insights": ml_insights,
                "ai_analysis": groq_analysis.get("analysis", "No disponible"),
                "model_info": groq_analysis.get("model_used", "simulacion"),
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
    
    def chat_with_ai(self, user_message: str, events_context: List[Dict[str, Any]] = None) -> Dict[str, Any]:
        """
        Chat inteligente que usa contexto ML para respuestas personalizadas
        """
        try:
            # Preparar contexto con insights ML
            context = {}
            if events_context:
                ml_insights = self.ml_models.get_schedule_insights(events_context)
                context = {
                    "ml_insights": ml_insights,
                    "events": events_context[:5],  # Solo eventos recientes
                    "current_date": datetime.now().strftime("%Y-%m-%d %H:%M")
                }
            
            # Chat con Groq incluyendo contexto ML
            response = self.groq_service.chat_with_assistant(user_message, context)
            
            return {
                "success": True,
                "user_message": user_message,
                "ai_response": response.get("response", "No disponible"),
                "model_used": response.get("model_used", "simulacion"),
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
        Genera contenido inteligente para eventos basado en ML + Groq
        """
        try:
            # 1. Análisis ML para contexto
            ml_context = {}
            if user_history:
                # Predecir tipo de evento y productividad
                title = partial_event.get('title', '')
                hour = partial_event.get('hour', 10)
                day_of_week = partial_event.get('day_of_week', 1)
                duration = partial_event.get('duration', 60)
                
                # Predicciones ML
                predicted_type = self.ml_models.classify_event(hour, day_of_week, duration, len(title))
                predicted_productivity = self.ml_models.predict_productivity(
                    hour, day_of_week, duration, 
                    'estudio' in title.lower(),
                    'trabajo' in title.lower(),
                    'ejercicio' in title.lower()
                )
                
                ml_context = {
                    "predicted_type": predicted_type,
                    "predicted_productivity": predicted_productivity,
                    "optimal_duration": self._suggest_optimal_duration(predicted_type),
                    "ml_confidence": 0.85  # Simulado para demo
                }
            
            # 2. Generar contenido con Groq
            enhanced_event = partial_event.copy()
            enhanced_event["context"] = f"ML sugiere: tipo '{ml_context.get('predicted_type', 'general')}', productividad esperada {ml_context.get('predicted_productivity', 0.5):.1%}"
            
            groq_result = self.groq_service.generate_event_content(enhanced_event)
            
            # 3. Combinar resultados ML + Groq
            result = {
                "success": True,
                "original_event": partial_event,
                "ml_predictions": ml_context,
                "generated_content": groq_result.get("generated_content", {}),
                "ai_model": groq_result.get("model_used", "simulacion"),
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
        Crea plan de estudio usando ML para optimizar horarios + Groq para estructura
        """
        try:
            # 1. Análisis ML de mejores horarios para estudio
            study_optimization = self._optimize_study_schedule(available_calendar)
            
            # 2. Formatear slots óptimos
            optimal_slots = study_optimization.get("optimal_slots", [])
            
            # 3. Generar plan con Groq
            groq_plan = self.groq_service.create_study_plan(subject, exam_date, optimal_slots)
            
            return {
                "success": True,
                "subject": subject,
                "exam_date": exam_date,
                "ml_optimization": study_optimization,
                "ai_study_plan": groq_plan.get("study_plan", "Plan no disponible"),
                "optimal_slots_count": len(optimal_slots),
                "model_used": "ML + " + groq_plan.get("model_used", "simulacion")
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
        Predice optimizaciones para la semana usando ML
        """
        try:
            if not current_week_events:
                return {"success": False, "message": "No hay eventos para analizar"}
            
            # Análisis ML de la semana
            insights = self.ml_models.get_schedule_insights(current_week_events)
            
            # Detectar problemas potenciales
            issues = []
            recommendations = []
            
            avg_productivity = insights.get('avg_productivity', 0.5)
            if avg_productivity < 0.6:
                issues.append("Productividad por debajo del óptimo")
                recommendations.append("Reorganizar eventos en horarios de mayor productividad")
            
            study_percentage = insights.get('study_percentage', 0)
            if study_percentage > 70:
                issues.append("Posible sobrecarga de estudio")
                recommendations.append("Incluir más descansos y actividad física")
            
            exercise_percentage = insights.get('exercise_percentage', 0)
            if exercise_percentage < 10:
                issues.append("Falta de actividad física")
                recommendations.append("Programar al menos 3 sesiones de ejercicio por semana")
            
            return {
                "success": True,
                "week_analysis": insights,
                "detected_issues": issues,
                "ml_recommendations": recommendations,
                "optimization_score": avg_productivity,
                "analysis_date": datetime.now().isoformat()
            }
            
        except Exception as e:
            print(f"❌ Error en predicción de optimización: {e}")
            return {
                "success": False,
                "error": str(e)
            }
    
    def _optimize_study_schedule(self, available_events: List[Dict[str, Any]]) -> Dict[str, Any]:
        """
        Optimiza horarios de estudio usando ML
        """
        # Simular análisis ML de mejores horarios
        optimal_slots = []
        
        # Horarios típicamente más productivos para estudio
        productive_hours = [9, 10, 11, 14, 15, 16, 19, 20]
        
        for hour in productive_hours:
            for day in range(5):  # Lunes a viernes
                productivity = self.ml_models.predict_productivity(
                    hour, day, 90, True, False, False
                )
                
                if productivity > 0.7:  # Solo horarios con alta productividad predicha
                    optimal_slots.append({
                        "day": day,
                        "hour": hour,
                        "productivity_score": productivity,
                        "duration": 90,
                        "type": "estudio"
                    })
        
        # Ordenar por productividad predicha
        optimal_slots.sort(key=lambda x: x["productivity_score"], reverse=True)
        
        return {
            "total_analyzed": len(available_events),
            "optimal_slots": optimal_slots[:8],  # Top 8 slots
            "avg_predicted_productivity": sum(slot["productivity_score"] for slot in optimal_slots) / len(optimal_slots) if optimal_slots else 0,
            "optimization_method": "ML RandomForest + heuristics"
        }
    
    def _suggest_optimal_duration(self, event_type: str) -> int:
        """
        Sugiere duración óptima basada en tipo de evento y research
        """
        durations = {
            "estudio": 90,      # Sesiones de 1.5h son óptimas para aprendizaje
            "trabajo": 60,      # Reuniones de 1h son más efectivas
            "ejercicio": 45,    # 45 min es suficiente para actividad física
            "personal": 30      # Actividades personales más flexibles
        }
        return durations.get(event_type, 60)
    
    def get_system_status(self) -> Dict[str, Any]:
        """
        Retorna estado del sistema ML + IA
        """
        return {
            "ml_models_trained": self.ml_models.models_trained,
            "groq_available": self.groq_service._is_available(),
            "system_ready": self.ml_models.models_trained,
            "capabilities": [
                "Análisis ML de patrones",
                "Predicción de productividad",
                "Clasificación de eventos",
                "Chat inteligente con Groq",
                "Generación de contenido",
                "Planes de estudio optimizados"
            ]
        }