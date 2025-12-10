"""
Prophet Trainer - Entrena modelos Prophet con historial de eventos
FALLBACK: Si Prophet falla, usa modelo estadístico simple
"""
try:
    from prophet import Prophet
    PROPHET_AVAILABLE = True
except:
    PROPHET_AVAILABLE = False
    print("⚠️  Prophet not available, using statistical fallback")

import pandas as pd
from datetime import datetime
import time
import warnings
warnings.filterwarnings('ignore')

class ProphetTrainer:
    """
    Entrena modelos Prophet para predecir productividad del usuario
    """
    
    def __init__(self):
        self.min_events = 20
        self.min_weeks = 2
    
    def train_model(self, user_id: str, events_history: list) -> dict:
        """
        Entrena modelo Prophet con historial de eventos
        Si Prophet no está disponible, usa modelo estadístico simple
        
        Returns:
            {
                'success': bool,
                'model': Prophet model or dict,
                'events_used': int,
                'training_time_seconds': float,
                'prophet_components': dict,
                'metadata': dict
            }
        """
        try:
            start_time = time.time()
            
            # Preparar datos en formato Prophet
            df = self._prepare_prophet_data(events_history)
            
            if df is None or len(df) < self.min_events:
                return {
                    'success': False,
                    'error': f'Insufficient data after preparation: {len(df) if df is not None else 0} events'
                }
            
            print(f"   Data prepared: {len(df)} data points")
            
            # Calcular semanas de datos
            weeks_of_data = self._calculate_weeks_of_data(df)
            
            # Intentar usar Prophet primero
            if PROPHET_AVAILABLE:
                print(f"   Attempting Prophet training...")
                prophet_result = self._train_with_prophet(user_id, df, weeks_of_data)
                if prophet_result['success']:
                    return prophet_result
                else:
                    print(f"   Prophet failed: {prophet_result.get('error', 'Unknown')}")
            
            # Fallback: Modelo estadístico simple
            print(f"   Using statistical fallback model...")
            return self._train_with_statistics(user_id, df, weeks_of_data, start_time)
            
        except Exception as e:
            print(f"   ❌ Training error: {e}")
            import traceback
            traceback.print_exc()
            return {
                'success': False,
                'error': str(e)
            }
    
    def _train_with_prophet(self, user_id: str, df: pd.DataFrame, weeks_of_data: float) -> dict:
        """Intenta entrenar con Prophet (puede fallar en Windows)"""
        try:
            from prophet import Prophet
            
            if weeks_of_data < 4:
                print(f"   Basic Prophet config (weeks: {weeks_of_data:.1f})")
                model = Prophet(
                    yearly_seasonality=False,
                    weekly_seasonality=True,
                    daily_seasonality=False,
                    seasonality_mode='additive',
                    changepoint_prior_scale=0.05,
                    interval_width=0.80
                )
            else:
                print(f"   Full Prophet config (weeks: {weeks_of_data:.1f})")
                model = Prophet(
                    yearly_seasonality=False,
                    weekly_seasonality=True,
                    daily_seasonality=True,
                    seasonality_mode='multiplicative',
                    changepoint_prior_scale=0.1,
                    interval_width=0.95
                )
            
            model.fit(df)
            
            prophet_components = self._analyze_prophet_components(model, df)
            
            return {
                'success': True,
                'model': model,
                'events_used': len(df),
                'training_time_seconds': 0,
                'prophet_components': prophet_components,
                'model_type': 'prophet',
                'metadata': {
                    'user_id': user_id,
                    'trained_at': datetime.now().isoformat(),
                    'events_count': len(df),
                    'weeks_of_data': weeks_of_data,
                    'prophet_components': prophet_components,
                    'model_type': 'prophet'
                }
            }
        except Exception as e:
            return {
                'success': False,
                'error': str(e)
            }
    
    def _train_with_statistics(self, user_id: str, df: pd.DataFrame, weeks_of_data: float, start_time: float) -> dict:
        """
        Modelo estadístico simple como fallback
        Analiza patrones por hora del día y día de la semana
        """
        try:
            # Agregar columnas de tiempo
            df['hour'] = df['ds'].dt.hour
            df['dayofweek'] = df['ds'].dt.dayofweek
            
            # Calcular productividad promedio por hora
            hourly_avg = df.groupby('hour')['y'].mean().to_dict()
            
            # Calcular productividad promedio por día de semana
            daily_avg = df.groupby('dayofweek')['y'].mean().to_dict()
            
            # Productividad general
            overall_avg = df['y'].mean()
            
            # Crear "modelo" estadístico
            statistical_model = {
                'type': 'statistical',
                'hourly_patterns': hourly_avg,
                'daily_patterns': daily_avg,
                'overall_avg': float(overall_avg),
                'total_events': len(df),
                'weeks_of_data': weeks_of_data
            }
            
            training_time = time.time() - start_time
            
            prophet_components = {
                'trend_detected': True,
                'weekly_seasonality': True,
                'daily_seasonality': len(hourly_avg) > 5,
                'yearly_seasonality': False,
                'model_type': 'statistical_fallback'
            }
            
            print(f"   ✅ Statistical model trained in {training_time:.2f}s")
            
            return {
                'success': True,
                'model': statistical_model,
                'events_used': len(df),
                'training_time_seconds': training_time,
                'prophet_components': prophet_components,
                'model_type': 'statistical',
                'metadata': {
                    'user_id': user_id,
                    'trained_at': datetime.now().isoformat(),
                    'events_count': len(df),
                    'weeks_of_data': weeks_of_data,
                    'prophet_components': prophet_components,
                    'model_type': 'statistical'
                }
            }
            
        except Exception as e:
            return {
                'success': False,
                'error': f'Statistical model failed: {str(e)}'
            }
    
    def _prepare_prophet_data(self, events_history: list) -> pd.DataFrame:
        """
        Convierte eventos en formato Prophet (ds, y)
        
        Prophet requiere:
        - ds: datetime (fecha del evento)
        - y: float (productividad: 1.0 = completado, 0.0 = no completado)
        """
        data = []
        
        for event in events_history:
            try:
                # Parsear fecha
                date_str = event.get('date', '').replace('Z', '+00:00')
                event_date = datetime.fromisoformat(date_str)
                
                # Calcular productividad basado en status (6 estados)
                status = event.get('status', 'pendiente').lower()
                
                # Eventos futuros: no contar
                if status in ['pendiente', 'confirmado']:
                    continue  # Skip eventos que aún no han ocurrido
                
                # Eventos completados: máxima productividad
                if status in ['finalizado', 'completado']:
                    productivity = 1.0
                
                # Eventos postergados: intentaste pero no pudiste
                elif status == 'postergado':
                    productivity = 0.3
                
                # Eventos no realizados o cancelados: no productivo
                elif status in ['no_realizado', 'cancelado']:
                    productivity = 0.0
                
                else:
                    productivity = 0.5  # Estados desconocidos
                
                data.append({
                    'ds': event_date,  # Prophet requiere columna 'ds'
                    'y': productivity   # Prophet requiere columna 'y'
                })
                
            except Exception as e:
                print(f"   ⚠️  Skipping event due to error: {e}")
                continue
        
        if not data:
            return None
        
        df = pd.DataFrame(data)
        
        # Agregar datos sintéticos si hay muy pocos
        if len(df) < 15:
            print(f"   ⚠️  Adding synthetic data (only {len(df)} real events)")
            df = self._add_synthetic_data(df)
        
        return df
    
    def _add_synthetic_data(self, df: pd.DataFrame) -> pd.DataFrame:
        """
        Agrega datos sintéticos para ayudar a Prophet con pocos datos reales
        Simula patrones típicos: alta productividad en mañanas de días laborales
        """
        if len(df) == 0:
            # Si no hay datos reales, crear patrón base completo
            today = datetime.now()
            synthetic_data = []
            
            for days_ago in range(30, 0, -1):
                for hour in [9, 10, 14, 15, 20]:
                    date = today.replace(hour=hour, minute=0, second=0, microsecond=0)
                    date = date - pd.Timedelta(days=days_ago)
                    
                    day_of_week = date.weekday()
                    
                    # Patrón: alta productividad en mañanas de días laborales
                    productivity = 0.5
                    
                    if day_of_week < 5:  # Lunes a viernes
                        productivity += 0.2
                    
                    if 9 <= hour <= 11:  # Mañanas
                        productivity += 0.2
                    elif 14 <= hour <= 16:  # Tardes
                        productivity += 0.1
                    
                    synthetic_data.append({
                        'ds': date,
                        'y': min(1.0, productivity)
                    })
            
            df = pd.DataFrame(synthetic_data)
        
        return df
    
    def _calculate_weeks_of_data(self, df: pd.DataFrame) -> float:
        """
        Calcula cuántas semanas de datos hay en el DataFrame
        """
        if len(df) < 2:
            return 0.0
        
        first_date = df['ds'].min()
        last_date = df['ds'].max()
        days_span = (last_date - first_date).days
        
        return days_span / 7.0
    
    def _analyze_prophet_components(self, model: Prophet, df: pd.DataFrame) -> dict:
        """
        Analiza qué componentes detectó Prophet en los datos
        """
        try:
            # Hacer predicción para analizar componentes
            forecast = model.predict(df)
            
            components = {
                'trend_detected': True,
                'weekly_seasonality': model.weekly_seasonality,
                'daily_seasonality': model.daily_seasonality if hasattr(model, 'daily_seasonality') else False,
                'yearly_seasonality': False
            }
            
            # Calcular fuerza de la estacionalidad semanal
            if 'weekly' in forecast.columns:
                weekly_strength = forecast['weekly'].std()
                components['weekly_seasonality_strength'] = round(float(weekly_strength), 3)
            
            return components
            
        except Exception as e:
            print(f"   ⚠️  Could not analyze components: {e}")
            return {
                'trend_detected': True,
                'weekly_seasonality': True,
                'daily_seasonality': False,
                'yearly_seasonality': False
            }
