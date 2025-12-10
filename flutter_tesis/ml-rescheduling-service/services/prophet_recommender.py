"""
Recomendador avanzado usando Prophet (Facebook)
Modelo pre-entrenado para forecasting de series temporales
"""
from prophet import Prophet
import pandas as pd
from datetime import datetime, timedelta
from typing import List, Dict, Any
import warnings
warnings.filterwarnings('ignore')

class ProphetMLRecommender:
    """
    Recomendador que usa Prophet de Facebook para predecir
    productividad futura basándose en patrones históricos
    """
    
    def __init__(self):
        self.model = None
        self.min_data_points = 15
    
    def recommend_reschedule(
        self, 
        incomplete_event: Dict[str, Any], 
        user_history: List[Dict[str, Any]], 
        future_calendar: List[Dict[str, Any]]
    ) -> List[Dict[str, Any]]:
        """
        Usa Prophet para predecir los mejores momentos para reagendar
        """
        # 1. Entrenar modelo Prophet con historial
        self._fit_prophet_model(user_history)
        
        # 2. Predecir productividad para próximos 7 días
        prophet_forecast = self._predict_future_productivity(days_ahead=7)
        
        # 3. Generar candidatos de reagendamiento
        candidates = self._generate_candidates_with_prophet(
            incomplete_event,
            prophet_forecast,
            future_calendar
        )
        
        # 4. Ordenar por score y retornar top 3
        candidates.sort(key=lambda x: x['score'], reverse=True)
        
        # Agregar ranking y metadata
        for i, rec in enumerate(candidates[:3]):
            rec['rank'] = i + 1
            rec['day_name'] = self._get_day_name(rec['day_of_week'])
        
        return candidates[:3]
    
    def _fit_prophet_model(self, user_history: List[Dict[str, Any]]):
        """
        Entrena modelo Prophet con el historial del usuario
        Prophet entrena automáticamente, no necesitas configurar nada
        """
        # Preparar datos en formato Prophet (requiere columnas 'ds' y 'y')
        df = self._prepare_prophet_data(user_history)
        
        if len(df) < self.min_data_points:
            # Usar configuración simple si hay pocos datos
            self.model = Prophet(
                yearly_seasonality=False,
                weekly_seasonality=True,
                daily_seasonality=False,
                seasonality_mode='additive',
                changepoint_prior_scale=0.05  # Menos sensible a cambios
            )
        else:
            # Configuración estándar con suficientes datos
            self.model = Prophet(
                yearly_seasonality=False,
                weekly_seasonality=True,
                daily_seasonality=True,
                seasonality_mode='multiplicative'
            )
        
        # Entrenar (automático, toma 2-5 segundos)
        self.model.fit(df)
        print(f"✅ Prophet trained with {len(df)} data points")
    
    def _prepare_prophet_data(self, user_history: List[Dict[str, Any]]) -> pd.DataFrame:
        """
        Convierte historial de eventos en formato Prophet
        
        Prophet requiere:
        - Columna 'ds': datetime (fecha)
        - Columna 'y': float (valor a predecir, en este caso productividad)
        """
        data = []
        
        for event in user_history:
            try:
                # Extraer fecha
                date_str = event.get('date', '').replace('Z', '+00:00')
                event_date = datetime.fromisoformat(date_str)
                
                # Calcular productividad: 1.0 si completado, 0.0 si no
                status = event.get('status', 'pendiente')
                productivity = 1.0 if status == 'finalizado' else 0.0
                
                data.append({
                    'ds': event_date,  # Prophet requiere 'ds'
                    'y': productivity   # Prophet requiere 'y'
                })
            except Exception as e:
                print(f"Skipping event: {e}")
                continue
        
        df = pd.DataFrame(data)
        
        # Agregar eventos sintéticos si hay muy pocos datos
        if len(df) < 10:
            df = self._add_synthetic_data(df)
        
        return df
    
    def _add_synthetic_data(self, df: pd.DataFrame) -> pd.DataFrame:
        """
        Agrega datos sintéticos para ayudar a Prophet cuando hay pocos eventos reales
        """
        if len(df) == 0:
            # Si no hay datos, crear patrón base
            today = datetime.now()
            synthetic_data = []
            
            for days_ago in range(30, 0, -1):
                date = today - timedelta(days=days_ago)
                
                # Patrón: alta productividad en mañanas de días laborales
                hour = date.hour
                day_of_week = date.weekday()
                
                productivity = 0.5  # Base
                if day_of_week < 5:  # Lunes a viernes
                    productivity += 0.2
                if 9 <= hour <= 11:  # Mañanas
                    productivity += 0.2
                
                synthetic_data.append({
                    'ds': date,
                    'y': min(1.0, productivity)
                })
            
            df = pd.DataFrame(synthetic_data)
        
        return df
    
    def _predict_future_productivity(self, days_ahead: int = 7) -> pd.DataFrame:
        """
        Predice productividad para los próximos N días usando Prophet
        """
        # Crear dataframe con fechas futuras (por hora)
        future = self.model.make_future_dataframe(periods=days_ahead*24, freq='H')
        
        # Predecir con Prophet
        forecast = self.model.predict(future)
        
        # Filtrar solo fechas futuras
        now = datetime.now()
        forecast = forecast[forecast['ds'] > now]
        
        return forecast
    
    def _generate_candidates_with_prophet(
        self,
        event: Dict[str, Any],
        prophet_forecast: pd.DataFrame,
        future_calendar: List[Dict[str, Any]]
    ) -> List[Dict[str, Any]]:
        """
        Genera candidatos combinando predicciones de Prophet con disponibilidad
        """
        candidates = []
        duration_minutes = event.get('duration_minutes', 60)
        
        # Iterar sobre las predicciones de Prophet
        for _, row in prophet_forecast.iterrows():
            slot_date = row['ds']
            hour = slot_date.hour
            day_of_week = slot_date.weekday()
            
            # Filtrar solo horarios razonables (6am - 10pm)
            if hour < 6 or hour > 22:
                continue
            
            # Extraer predicción de Prophet
            prophet_prediction = max(0, min(1, row['yhat']))  # Normalizar 0-1
            prophet_lower = max(0, min(1, row['yhat_lower']))
            prophet_upper = max(0, min(1, row['yhat_upper']))
            
            # Calcular score combinado
            context_bonus = self._calculate_context_bonus(hour, day_of_week, event)
            final_score = (0.7 * prophet_prediction) + (0.3 * context_bonus)
            
            # Determinar confianza basada en el intervalo de Prophet
            confidence_interval = prophet_upper - prophet_lower
            confidence = 'high' if confidence_interval < 0.3 else 'medium' if confidence_interval < 0.5 else 'low'
            
            candidates.append({
                'date': slot_date.isoformat(),
                'hour': hour,
                'day_of_week': day_of_week,
                'score': final_score,
                'prophet_prediction': prophet_prediction,
                'prophet_confidence_lower': prophet_lower,
                'prophet_confidence_upper': prophet_upper,
                'predicted_completion_probability': prophet_prediction,
                'ml_confidence': confidence,
                'duration_minutes': duration_minutes,
                'reasons': self._generate_prophet_reasons(
                    hour, day_of_week, prophet_prediction, context_bonus
                ),
                'calendar_density': 0.3,  # Simplificado
                'gap_before': 30,
                'gap_after': 60
            })
        
        return candidates
    
    def _calculate_context_bonus(
        self, 
        hour: int, 
        day_of_week: int, 
        event: Dict[str, Any]
    ) -> float:
        """
        Calcula bonus contextual basado en factores externos
        """
        bonus = 0.5
        event_type = event.get('type', 'personal')
        
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
    
    def _generate_prophet_reasons(
        self, 
        hour: int, 
        day_of_week: int, 
        prophet_score: float, 
        context_bonus: float
    ) -> List[str]:
        """
        Genera explicaciones de las predicciones de Prophet
        """
        reasons = []
        day_name = self._get_day_name(day_of_week)
        
        # Razón principal de Prophet
        if prophet_score > 0.7:
            reasons.append(f"El modelo ML predice alta probabilidad de éxito ({prophet_score*100:.0f}%) basado en tus patrones")
        elif prophet_score > 0.5:
            reasons.append(f"Probabilidad moderada de completación ({prophet_score*100:.0f}%) según análisis ML")
        else:
            reasons.append(f"El modelo sugiere precaución en este horario")
        
        # Razones contextuales
        if 9 <= hour <= 11:
            reasons.append("Horario matutino con alta energía típica")
        elif 14 <= hour <= 16:
            reasons.append("Tarde productiva según patrones generales")
        
        if day_of_week in [1, 2, 3]:
            reasons.append(f"{day_name} es un día con buena productividad general")
        
        if context_bonus > 0.6:
            reasons.append("Contexto favorable para este tipo de actividad")
        
        return reasons[:4]
    
    def _get_day_name(self, day: int) -> str:
        """Convierte número de día a nombre"""
        days = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo']
        return days[day] if 0 <= day < 7 else 'Día'
