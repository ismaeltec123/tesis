"""
Servicio Groq para comunicación con IA ext            response = self.client.chat.completions.create(
                model="llama3-70b-8192",
                messages=messages,
                temperature=0.5,
"""
import os
from typing import List, Dict, Any, Optional
import json
from datetime import datetime

try:
    from groq import Groq
    GROQ_AVAILABLE = True
except ImportError:
    GROQ_AVAILABLE = False
    print("⚠️  Groq no disponible, usando simulación")

class GroqService:
    def __init__(self):
        self.client = None
        self.api_key = os.getenv('GROQ_API_KEY')
        
        if GROQ_AVAILABLE and self.api_key:
            try:
                self.client = Groq(api_key=self.api_key)
                print("✅ Groq inicializado correctamente")
            except Exception as e:
                print(f"⚠️  Error inicializando Groq: {e}")
                self.client = None
        else:
            print("⚠️  Groq no configurado, usando respuestas simuladas")
    
    def chat_with_assistant(self, user_message: str, calendar_context: Dict[str, Any] = None) -> Dict[str, Any]:
        """
        Chat conversacional con el asistente de calendario
        """
        if not self._is_available():
            return self._simulate_chat_response(user_message, calendar_context)
        
        try:
            # Construir contexto para Groq
            system_prompt = self._build_system_prompt()
            context_message = self._build_context_message(calendar_context)
            
            messages = [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": f"{context_message}\n\nUsuario pregunta: {user_message}"}
            ]
            
            response = self.client.chat.completions.create(
                model="llama3-70b-8192",
                messages=messages,
                temperature=0.7,
                max_tokens=1024
            )
            
            ai_response = response.choices[0].message.content
            
            return {
                "success": True,
                "response": ai_response,
                "model_used": "llama3-70b-8192",
                "tokens_used": response.usage.total_tokens if hasattr(response, 'usage') else 0
            }
            
        except Exception as e:
            print(f"Error en Groq chat: {e}")
            return self._simulate_chat_response(user_message, calendar_context)
    
    def analyze_calendar_with_ml(self, ml_insights: Dict[str, Any], events: List[Dict[str, Any]]) -> Dict[str, Any]:
        """
        Análisis inteligente del calendario combinando ML insights con interpretación de Groq
        """
        if not self._is_available():
            return self._simulate_calendar_analysis(ml_insights, events)
        
        try:
            # Preparar prompt con datos ML
            analysis_prompt = self._build_ml_analysis_prompt(ml_insights, events)
            
            messages = [
                {"role": "system", "content": "Eres un asistente experto en productividad y organización de tiempo. Analiza datos de machine learning sobre patrones de usuario y proporciona insights accionables en español."},
                {"role": "user", "content": analysis_prompt}
            ]
            
            response = self.client.chat.completions.create(
                model="llama3-70b-8192",
                messages=messages,
                temperature=0.6,
                max_tokens=1500
            )
            
            analysis = response.choices[0].message.content
            
            return {
                "success": True,
                "analysis": analysis,
                "ml_data": ml_insights,
                "model_used": "llama3-70b-8192"
            }
            
        except Exception as e:
            print(f"Error en análisis Groq: {e}")
            return self._simulate_calendar_analysis(ml_insights, events)
    
    def generate_event_content(self, partial_event: Dict[str, Any]) -> Dict[str, Any]:
        """
        Genera contenido inteligente para un evento basado en información parcial
        """
        if not self._is_available():
            return self._simulate_event_generation(partial_event)
        
        try:
            title = partial_event.get('title', '')
            context = partial_event.get('context', '')
            
            prompt = f"""
            Necesito completar la información de un evento de calendario:
            
            Título actual: "{title}"
            Contexto adicional: "{context}"
            
            Por favor, genera:
            1. Un título más descriptivo y profesional
            2. Una descripción detallada que incluya objetivos y preparativos
            3. Duración sugerida en minutos
            4. Tipo de evento (estudio, trabajo, personal, ejercicio)
            5. Lista de preparativos o materiales necesarios
            
            Responde en formato JSON con las claves: title, description, duration_minutes, type, preparations
            """
            
            messages = [
                {"role": "system", "content": "Eres un asistente que ayuda a organizar calendarios. Siempre responde en formato JSON válido."},
                {"role": "user", "content": prompt}
            ]
            
            response = self.client.chat.completions.create(
                model="llama-3.1-8b-instant",  # Modelo más rápido para esta tarea
                messages=messages,
                temperature=0.5,
                max_tokens=800
            )
            
            content = response.choices[0].message.content
            
            # Intentar parsear como JSON
            try:
                generated_content = json.loads(content)
                return {
                    "success": True,
                    "generated_content": generated_content,
                    "original_input": partial_event
                }
            except json.JSONDecodeError:
                # Si no es JSON válido, procesar como texto
                return {
                    "success": True,
                    "generated_content": {"description": content},
                    "original_input": partial_event
                }
                
        except Exception as e:
            print(f"Error generando contenido: {e}")
            return self._simulate_event_generation(partial_event)
    
    def create_study_plan(self, subject: str, exam_date: str, available_slots: List[Dict]) -> Dict[str, Any]:
        """
        Crea un plan de estudio inteligente
        """
        if not self._is_available():
            return self._simulate_study_plan(subject, exam_date, available_slots)
        
        try:
            prompt = f"""
            Necesito crear un plan de estudio para:
            - Materia: {subject}
            - Fecha del examen: {exam_date}
            - Espacios disponibles en mi calendario: {len(available_slots)} slots
            
            Horarios disponibles:
            {self._format_available_slots(available_slots)}
            
            Por favor, crea un plan de estudio detallado que incluya:
            1. Sesiones de estudio distribuidas en los horarios disponibles
            2. Temas específicos para cada sesión
            3. Duración óptima para cada sesión
            4. Método de estudio recomendado para cada tema
            5. Revisiones y práctica antes del examen
            
            Responde con un plan estructurado y práctico.
            """
            
            messages = [
                {"role": "system", "content": "Eres un experto en técnicas de estudio y planificación académica. Creas planes de estudio efectivos y realistas."},
                {"role": "user", "content": prompt}
            ]
            
            response = self.client.chat.completions.create(
                model="llama3-70b-8192",
                messages=messages,
                temperature=0.6,
                max_tokens=2000
            )
            
            study_plan = response.choices[0].message.content
            
            return {
                "success": True,
                "study_plan": study_plan,
                "subject": subject,
                "exam_date": exam_date,
                "available_slots": len(available_slots)
            }
            
        except Exception as e:
            print(f"Error creando plan de estudio: {e}")
            return self._simulate_study_plan(subject, exam_date, available_slots)
    
    def _is_available(self) -> bool:
        """Verifica si Groq está disponible"""
        return GROQ_AVAILABLE and self.client is not None
    
    def _build_system_prompt(self) -> str:
        """Construye el prompt del sistema para el asistente"""
        return """
        Eres un asistente personal inteligente especializado en organización de calendarios y productividad. 
        Tu nombre es CalendarAI y ayudas a estudiantes universitarios a optimizar su tiempo.
        
        Características:
        - Respondes siempre en español
        - Eres amigable pero profesional
        - Das consejos basados en evidencia científica sobre productividad
        - Analizas patrones de comportamiento para dar recomendaciones personalizadas
        - Sugieres horarios óptimos basados en cronobiología
        - Ayudas a balancear estudio, trabajo y bienestar personal
        
        Siempre proporciona respuestas útiles y accionables.
        """
    
    def _build_context_message(self, context: Dict[str, Any]) -> str:
        """Construye mensaje de contexto con información del calendario"""
        if not context:
            return "El usuario no ha proporcionado contexto específico del calendario."
        
        message = "CONTEXTO DEL CALENDARIO DEL USUARIO:\n"
        
        if "events" in context:
            message += f"- Eventos próximos: {len(context['events'])}\n"
        
        if "ml_insights" in context:
            insights = context["ml_insights"]
            message += f"- Productividad promedio: {insights.get('avg_productivity', 0):.2f}\n"
            message += f"- Mejor hora del día: {insights.get('best_hour', 'No determinada')}\n"
            message += f"- Duración promedio de eventos: {insights.get('avg_duration', 0):.0f} minutos\n"
        
        if "current_date" in context:
            message += f"- Fecha actual: {context['current_date']}\n"
        
        return message
    
    def _build_ml_analysis_prompt(self, ml_insights: Dict[str, Any], events: List[Dict[str, Any]]) -> str:
        """Construye prompt para análisis combinado ML + LLM"""
        prompt = f"""
        ANÁLISIS DE MACHINE LEARNING DEL USUARIO:
        
        Datos generales:
        - Total de eventos analizados: {ml_insights.get('total_events', 0)}
        - Productividad promedio: {ml_insights.get('avg_productivity', 0):.2f}/1.0
        - Mejor hora del día: {ml_insights.get('best_hour', 'No determinada')}h
        - Mejor día de la semana: {self._get_day_name(ml_insights.get('best_day', 0))}
        - Duración promedio de eventos: {ml_insights.get('avg_duration', 0):.0f} minutos
        
        Distribución de actividades:
        - Estudio: {ml_insights.get('study_percentage', 0):.1f}%
        - Trabajo: {ml_insights.get('work_percentage', 0):.1f}%
        - Ejercicio: {ml_insights.get('exercise_percentage', 0):.1f}%
        
        Productividad por horarios:
        - Mañana: {ml_insights.get('morning_productivity', 0):.2f}/1.0
        - Tarde: {ml_insights.get('afternoon_productivity', 0):.2f}/1.0
        - Noche: {ml_insights.get('evening_productivity', 0):.2f}/1.0
        
        Eventos recientes: {len(events)} eventos
        
        Por favor, analiza estos datos y proporciona:
        1. Insights sobre patrones de productividad del usuario
        2. Recomendaciones específicas para optimizar su horario
        3. Sugerencias para mejorar el balance de actividades
        4. Alertas sobre posibles problemas (sobrecarga, falta de ejercicio, etc.)
        5. Plan de acción concreto para la próxima semana
        
        Responde de manera conversacional y útil, como si fueras un coach de productividad personal.
        """
        
        return prompt
    
    def _format_available_slots(self, slots: List[Dict]) -> str:
        """Formatea slots disponibles para el prompt"""
        if not slots:
            return "No hay horarios disponibles"
        
        formatted = []
        for i, slot in enumerate(slots[:5]):  # Limitar a 5 slots para el prompt
            start = slot.get('start', 'No definido')
            end = slot.get('end', 'No definido')
            duration = slot.get('duration', 0)
            formatted.append(f"  {i+1}. {start} - {end} ({duration} min)")
        
        return "\n".join(formatted)
    
    def _get_day_name(self, day_number: int) -> str:
        """Convierte número de día a nombre"""
        days = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo']
        return days[day_number] if 0 <= day_number < 7 else 'No determinado'
    
    # Métodos de simulación para cuando Groq no está disponible
    def _simulate_chat_response(self, message: str, context: Dict = None) -> Dict[str, Any]:
        """Simulación de respuesta de chat para demo"""
        responses = {
            "organiza mi semana": "He analizado tu calendario y veo que tienes una buena distribución de actividades. Te sugiero concentrar las tareas de estudio en las mañanas (9-11h) cuando tu productividad es mayor, y programar ejercicio en las tardes.",
            "cómo está mi calendario": "Tu calendario muestra un patrón interesante: eres más productivo los martes y miércoles. Sin embargo, podrías beneficiarte de más tiempo para ejercicio. ¿Te gustaría que sugiera algunos ajustes?",
            "crear plan de estudio": "Para crear un plan de estudio efectivo, necesito saber la materia y la fecha del examen. Basándome en tus patrones, te sugiero sesiones de 90 minutos con descansos de 15 minutos."
        }
        
        # Buscar respuesta similar
        response_text = "Soy tu asistente de calendario IA. Puedo ayudarte a organizar tu tiempo, analizar patrones de productividad y crear planes de estudio. ¿En qué puedo ayudarte específicamente?"
        
        for key, value in responses.items():
            if key.lower() in message.lower():
                response_text = value
                break
        
        return {
            "success": True,
            "response": response_text,
            "model_used": "simulacion",
            "note": "Esta es una respuesta simulada para demo. Configura GROQ_API_KEY para usar IA real."
        }
    
    def _simulate_calendar_analysis(self, ml_insights: Dict, events: List) -> Dict[str, Any]:
        """Simulación de análisis de calendario"""
        avg_productivity = ml_insights.get('avg_productivity', 0.65)
        best_hour = ml_insights.get('best_hour', 10)
        
        analysis = f"""
        📊 ANÁLISIS DE TU CALENDARIO
        
        Basándome en el análisis de machine learning de tus {ml_insights.get('total_events', 0)} eventos:
        
        🎯 PATRONES DETECTADOS:
        • Tu productividad promedio es {avg_productivity:.1%}
        • Tu mejor hora del día es a las {best_hour}:00h
        • Eres más productivo durante las {self._get_best_time_period(ml_insights)}
        
        📈 DISTRIBUCIÓN DE ACTIVIDADES:
        • Estudio: {ml_insights.get('study_percentage', 0):.0f}%
        • Trabajo: {ml_insights.get('work_percentage', 0):.0f}%
        • Ejercicio: {ml_insights.get('exercise_percentage', 0):.0f}%
        
        💡 RECOMENDACIONES:
        1. Programa tareas importantes entre {best_hour-1}:00h y {best_hour+2}:00h
        2. {"Aumenta el tiempo de ejercicio" if ml_insights.get('exercise_percentage', 0) < 15 else "Mantén tu rutina de ejercicio"}
        3. {"Considera sesiones de estudio más cortas" if ml_insights.get('avg_duration', 60) > 120 else "Tu duración de sesiones es óptima"}
        
        🎯 PRÓXIMOS PASOS:
        • Bloquea tiempo de alta productividad para tareas complejas
        • Mantén consistencia en tus mejores horarios
        • Balancea trabajo mental con actividad física
        """
        
        return {
            "success": True,
            "analysis": analysis,
            "ml_data": ml_insights,
            "model_used": "simulacion"
        }
    
    def _simulate_event_generation(self, partial_event: Dict) -> Dict[str, Any]:
        """Simulación de generación de contenido de evento"""
        title = partial_event.get('title', '').lower()
        
        generated = {
            "title": f"📚 {partial_event.get('title', 'Evento').title()}",
            "description": "Evento generado por IA de demostración. Configura GROQ_API_KEY para generación inteligente real.",
            "duration_minutes": 60,
            "type": "general",
            "preparations": ["Revisar material previo", "Preparar espacio de trabajo"]
        }
        
        # Personalizar según el título
        if any(word in title for word in ['estudio', 'estudiar', 'examen']):
            generated.update({
                "title": f"📚 Sesión de {partial_event.get('title', 'Estudio').title()}",
                "description": "Sesión de estudio enfocada con objetivos específicos y metodología activa.",
                "duration_minutes": 90,
                "type": "estudio",
                "preparations": ["Revisar apuntes anteriores", "Preparar material de estudio", "Eliminar distracciones"]
            })
        elif any(word in title for word in ['reunion', 'meeting', 'trabajo']):
            generated.update({
                "title": f"💼 {partial_event.get('title', 'Reunión').title()}",
                "description": "Reunión de trabajo con agenda definida y objetivos claros.",
                "duration_minutes": 60,
                "type": "trabajo",
                "preparations": ["Revisar agenda", "Preparar materiales", "Confirmar asistencia"]
            })
        
        return {
            "success": True,
            "generated_content": generated,
            "original_input": partial_event,
            "note": "Contenido generado por simulación. Configura GROQ_API_KEY para IA real."
        }
    
    def _simulate_study_plan(self, subject: str, exam_date: str, available_slots: List) -> Dict[str, Any]:
        """Simulación de plan de estudio"""
        plan = f"""
        📚 PLAN DE ESTUDIO - {subject.upper()}
        
        🎯 Objetivo: Examen el {exam_date}
        📅 Sesiones programadas: {len(available_slots)} disponibles
        
        📋 DISTRIBUCIÓN SUGERIDA:
        
        Semana 1: Revisión de fundamentos
        • Sesión 1 (90 min): Conceptos básicos y teoría
        • Sesión 2 (60 min): Ejercicios introductorios
        
        Semana 2: Práctica intensiva
        • Sesión 3 (90 min): Problemas intermedios
        • Sesión 4 (60 min): Casos prácticos
        
        Días finales: Repaso y consolidación
        • Sesión 5 (45 min): Repaso general
        • Sesión 6 (30 min): Simulacro de examen
        
        💡 TÉCNICAS RECOMENDADAS:
        • Técnica Pomodoro (25 min estudio + 5 min descanso)
        • Mapas mentales para conceptos complejos
        • Práctica activa con ejercicios
        • Explicar conceptos en voz alta
        
        🎯 TIPS PARA EL EXAMEN:
        • Dormir 7-8 horas la noche anterior
        • Desayunar bien el día del examen
        • Llegar 15 minutos antes
        • Leer todas las preguntas antes de empezar
        """
        
        return {
            "success": True,
            "study_plan": plan,
            "subject": subject,
            "exam_date": exam_date,
            "available_slots": len(available_slots),
            "note": "Plan generado por simulación. Configura GROQ_API_KEY para planes personalizados."
        }
    
    def _get_best_time_period(self, ml_insights: Dict) -> str:
        """Determina el mejor período del día basado en ML insights"""
        morning = ml_insights.get('morning_productivity', 0)
        afternoon = ml_insights.get('afternoon_productivity', 0)
        evening = ml_insights.get('evening_productivity', 0)
        
        if morning >= afternoon and morning >= evening:
            return "mañanas"
        elif afternoon >= evening:
            return "tardes"
        else:
            return "noches"