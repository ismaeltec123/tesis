"""
Prophet Predictor - Genera predicciones de reagendamiento usando Prophet
FALLBACK: Si el modelo es estadístico, usa patrones históricos
"""
try:
    from prophet import Prophet
    PROPHET_AVAILABLE = True
except:
    PROPHET_AVAILABLE = False

import pandas as pd
from datetime import datetime, timedelta
from typing import Dict, List, Any
import warnings
warnings.filterwarnings('ignore')

class ProphetPredictor:
    """
    Genera predicciones de mejores horarios usando modelo Prophet entrenado
    """
    
    def __init__(self):
        pass
    
    def predict_reschedule(
        self,
        user_id: str,
        model: any,
        incomplete_event: dict,
        events_history: list,
        future_calendar: list,
        model_metadata: dict
    ) -> dict:
        """
        Genera las 3 mejores sugerencias de reagendamiento
        Funciona con Prophet o modelo estadístico
        
        Returns:
            {
                'success': bool,
                'recommendations': list,
                'confidence': str,
                'metrics': dict
            }
        """
        try:
            print(f"   Generating predictions for event: {incomplete_event.get('title', 'Untitled')}")
            
            # Determinar tipo de modelo
            model_type = model_metadata.get('model_type', 'unknown')
            
            if isinstance(model, dict) and model.get('type') == 'statistical':
                # Modelo estadístico
                print(f"   Using statistical model")
                forecast = self._predict_with_statistical_model(model, days_ahead=7)
            elif PROPHET_AVAILABLE and hasattr(model, 'predict'):
                # Modelo Prophet
                print(f"   Using Prophet model")
                forecast = self._predict_future_productivity(model, days_ahead=7)
            else:
                return {
                    'success': False,
                    'error': 'Unknown model type or Prophet not available'
                }
            
            if forecast is None or len(forecast) == 0:
                return {
                    'success': False,
                    'error': 'Could not generate forecast'
                }
            
            print(f"   Generated {len(forecast)} hourly predictions")
            
            # Generar candidatos de reagendamiento
            candidates = self._generate_candidates(
                incomplete_event=incomplete_event,
                forecast=forecast,
                future_calendar=future_calendar,
                model_type=model_type
            )
            
            print(f"   Found {len(candidates)} candidate slots")
            
            # Ordenar y seleccionar top 3
            candidates.sort(key=lambda x: x['score'], reverse=True)
            top_3 = candidates[:3]
            
            # Determinar nivel de confianza
            weeks_of_data = model_metadata.get('weeks_of_data', 0)
            events_count = model_metadata.get('events_count', 0)
            
            if weeks_of_data >= 4 and events_count >= 50:
                confidence = 'high'
            elif weeks_of_data >= 2 and events_count >= 20:
                confidence = 'medium'
            else:
                confidence = 'low'
            
            # Calcular métricas
            metrics = {
                'total_events_analyzed': events_count,
                'weeks_of_data': round(weeks_of_data, 2),
                'model_accuracy_estimate': self._estimate_accuracy(weeks_of_data, events_count),
                'candidates_generated': len(candidates),
                'top_score': top_3[0]['score'] if top_3 else 0,
                'model_type': model_type
            }
            
            return {
                'success': True,
                'recommendations': top_3,
                'confidence': confidence,
                'metrics': metrics
            }
            
        except Exception as e:
            print(f"   ❌ Prediction error: {e}")
            import traceback
            traceback.print_exc()
            return {
                'success': False,
                'error': str(e)
            }
    
    def _predict_with_statistical_model(self, model: dict, days_ahead: int = 7) -> pd.DataFrame:
        """
        Genera predicciones usando modelo estadístico simple
        """
        try:
            hourly_patterns = model.get('hourly_patterns', {})
            daily_patterns = model.get('daily_patterns', {})
            overall_avg = model.get('overall_avg', 0.5)
            
            predictions = []
            now = datetime.now()
            
            # Generar predicciones para próximos N días (hora por hora)
            for day_offset in range(days_ahead):
                for hour in range(24):
                    pred_date = now + timedelta(days=day_offset, hours=hour - now.hour)
                    pred_date = pred_date.replace(minute=0, second=0, microsecond=0)
                    
                    if pred_date <= now:
                        continue
                    
                    day_of_week = pred_date.weekday()
                    
                    # Combinar patrones
                    hourly_score = hourly_patterns.get(hour, overall_avg)
                    daily_score = daily_patterns.get(day_of_week, overall_avg)
                    
                    # Promedio ponderado
                    yhat = (0.6 * hourly_score) + (0.4 * daily_score)
                    
                    predictions.append({
                        'ds': pred_date,
                        'yhat': yhat,
                        'yhat_lower': max(0, yhat - 0.2),
                        'yhat_upper': min(1, yhat + 0.2),
                        'trend': yhat,
                        'weekly': 0
                    })
            
            return pd.DataFrame(predictions)
            
        except Exception as e:
            print(f"   ❌ Statistical prediction error: {e}")
            return None
    
    def _predict_future_productivity(self, model, days_ahead: int = 7) -> pd.DataFrame:
        """
        Predice productividad para los próximos N días (hora por hora)
        """
        try:
            # Crear dataframe con fechas futuras (cada hora)
            future = model.make_future_dataframe(periods=days_ahead * 24, freq='H')
            
            # Predecir con Prophet
            forecast = model.predict(future)
            
            # Filtrar solo fechas futuras
            now = datetime.now()
            forecast = forecast[forecast['ds'] > now]
            
            return forecast
            
        except Exception as e:
            print(f"   ❌ Forecast error: {e}")
            return None
    
    def _generate_candidates(
        self,
        incomplete_event: dict,
        forecast: pd.DataFrame,
        future_calendar: list,
        model_type: str = 'unknown'
    ) -> List[Dict[str, Any]]:
        """
        Genera slots candidatos combinando predicciones con disponibilidad
        Filtra conflictos con el calendario futuro
        """
        candidates = []
        duration_minutes = incomplete_event.get('duration_minutes', 60)
        event_type = incomplete_event.get('type', 'personal')
        
        # Convertir future_calendar a lista de rangos ocupados
        busy_ranges = self._parse_busy_times(future_calendar)
        
        # Iterar sobre predicciones
        for _, row in forecast.iterrows():
            slot_date = row['ds']
            
            # Asegurar que slot_date sea offset-naive
            if hasattr(slot_date, 'tzinfo') and slot_date.tzinfo is not None:
                slot_date = slot_date.replace(tzinfo=None)
            
            hour = slot_date.hour
            day_of_week = slot_date.weekday()
            
            # Filtrar solo horarios razonables (6am - 10pm)
            if hour < 6 or hour > 22:
                continue
            
            # ✅ NUEVO: Verificar conflictos con calendario futuro
            slot_end = slot_date + timedelta(minutes=duration_minutes)
            if self._has_conflict(slot_date, slot_end, busy_ranges):
                continue  # Skip horarios ocupados
            
            # Extraer predicción
            prophet_prediction = max(0, min(1, row['yhat']))
            prophet_lower = max(0, min(1, row['yhat_lower']))
            prophet_upper = max(0, min(1, row['yhat_upper']))
            
            # Calcular bonus contextual
            context_bonus = self._calculate_context_bonus(hour, day_of_week, event_type)
            
            # Score final (70% ML, 30% contexto)
            final_score = (0.7 * prophet_prediction) + (0.3 * context_bonus)
            
            # Generar razones interpretables
            reasons = self._generate_reasons(
                hour=hour,
                day_of_week=day_of_week,
                prophet_score=prophet_prediction,
                context_bonus=context_bonus,
                event_type=event_type,
                model_type=model_type
            )
            
            # Determinar intervalo de confianza
            confidence_interval = prophet_upper - prophet_lower
            if confidence_interval < 0.3:
                ml_confidence = 'high'
            elif confidence_interval < 0.5:
                ml_confidence = 'medium'
            else:
                ml_confidence = 'low'
            
            candidates.append({
                'date': slot_date.isoformat(),
                'day_name': self._get_day_name(day_of_week),
                'hour': hour,
                'day_of_week': day_of_week,
                'score': round(final_score, 2),
                'completion_probability': round(prophet_prediction, 2),
                'reasons': reasons,
                'ml_confidence': ml_confidence,
                'prophet_details': {
                    'yhat': round(prophet_prediction, 2),
                    'yhat_lower': round(prophet_lower, 2),
                    'yhat_upper': round(prophet_upper, 2)
                }
            })
        
        return candidates
    
    def _parse_busy_times(self, future_calendar: list) -> List[tuple]:
        """
        Convierte future_calendar a lista de rangos (start, end) ocupados
        """
        busy_ranges = []
        
        for event in future_calendar:
            try:
                start_str = event.get('date', '').replace('Z', '+00:00')
                start = datetime.fromisoformat(start_str)
                
                # Si tiene end_time, usarlo; si no, asumir 1 hora
                if 'end_time' in event:
                    end_str = event.get('end_time', '').replace('Z', '+00:00')
                    end = datetime.fromisoformat(end_str)
                else:
                    end = start + timedelta(hours=1)
                
                # Convertir a offset-naive para comparación
                if start.tzinfo is not None:
                    start = start.replace(tzinfo=None)
                if end.tzinfo is not None:
                    end = end.replace(tzinfo=None)
                
                busy_ranges.append((start, end))
            except Exception as e:
                print(f"   ⚠️  Error parsing event: {e}")
                continue
        
        return busy_ranges
    
    def _has_conflict(self, slot_start: datetime, slot_end: datetime, busy_ranges: List[tuple]) -> bool:
        """
        Verifica si el slot propuesto tiene conflicto con eventos existentes
        Retorna True si hay conflicto (solapamiento)
        """
        for busy_start, busy_end in busy_ranges:
            # Hay conflicto si hay cualquier solapamiento
            if slot_start < busy_end and slot_end > busy_start:
                return True
        
        return False
    
    def _calculate_context_bonus(self, hour: int, day_of_week: int, event_type: str) -> float:
        """
        Calcula bonus contextual basado en factores externos
        """
        bonus = 0.5
        
        # Bonus por horario óptimo
        if 9 <= hour <= 11:
            bonus += 0.3  # Mañana productiva
        elif 14 <= hour <= 16:
            bonus += 0.2  # Tarde buena
        elif hour < 8 or hour > 21:
            bonus -= 0.3  # Muy temprano/tarde
        
        # Bonus por día de semana
        if day_of_week in [1, 2, 3]:  # Martes, Miércoles, Jueves
            bonus += 0.15
        elif day_of_week >= 5:  # Fin de semana
            if event_type in ['trabajo', 'estudio']:
                bonus -= 0.2
            else:
                bonus += 0.1
        
        return max(0, min(1, bonus))
    
    def _generate_reasons(
        self,
        hour: int,
        day_of_week: int,
        prophet_score: float,
        context_bonus: float,
        event_type: str,
        model_type: str = 'unknown'
    ) -> List[str]:
        """
        Genera explicaciones interpretables de las predicciones
        """
        reasons = []
        day_name = self._get_day_name(day_of_week)
        
        # Razón principal según tipo de modelo
        ml_name = "Prophet" if model_type == "prophet" else "el sistema ML"
        events_analyzed = "tus patrones históricos"
        
        if prophet_score > 0.75:
            reasons.append(f"{ml_name} predice {int(prophet_score*100)}% de éxito basado en {events_analyzed}")
        elif prophet_score > 0.60:
            reasons.append(f"Probabilidad moderada de completación ({int(prophet_score*100)}%) según análisis ML")
        elif prophet_score > 0.45:
            reasons.append(f"Probabilidad media ({int(prophet_score*100)}%) según tu historial")
        else:
            reasons.append(f"El modelo sugiere precaución en este horario ({int(prophet_score*100)}%)")
        
        # Razones contextuales
        if 9 <= hour <= 11:
            reasons.append("Horario matutino con alta energía típica")
        elif 14 <= hour <= 16:
            reasons.append("Tarde productiva según patrones generales")
        elif hour >= 20:
            reasons.append("⚠️ Horario nocturno, menor productividad esperada")
        
        if day_of_week in [1, 2, 3]:
            reasons.append(f"{day_name} es un día con buena productividad general")
        elif day_of_week == 0:
            reasons.append(f"{day_name}: inicio de semana con energía renovada")
        elif day_of_week >= 5:
            if event_type in ['trabajo', 'estudio']:
                reasons.append(f"⚠️ {day_name}: fin de semana puede afectar concentración")
        
        if context_bonus > 0.65:
            reasons.append("Contexto favorable para este tipo de actividad")
        
        return reasons[:4]  # Máximo 4 razones
    
    def _get_day_name(self, day: int) -> str:
        """Convierte número de día a nombre en español"""
        days = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo']
        return days[day] if 0 <= day < 7 else 'Día'
    
    def _estimate_accuracy(self, weeks_of_data: float, events_count: int) -> float:
        """
        Estima la precisión del modelo basándose en cantidad de datos
        """
        # Fórmula simple: más datos = mayor precisión
        base_accuracy = 0.60
        
        # Bonus por semanas de datos
        weeks_bonus = min(0.15, (weeks_of_data / 10) * 0.15)
        
        # Bonus por cantidad de eventos
        events_bonus = min(0.15, (events_count / 100) * 0.15)
        
        accuracy = base_accuracy + weeks_bonus + events_bonus
        
        return round(min(0.95, accuracy), 2)
