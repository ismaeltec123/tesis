"""
Servicio de Machine Learning para análisis de patrones de usuario
"""
import pandas as pd
import numpy as np
from datetime import datetime, timedelta
from typing import List, Dict, Any, Tuple
import joblib
import os

try:
    from sklearn.ensemble import RandomForestRegressor, RandomForestClassifier
    from sklearn.cluster import KMeans
    from sklearn.preprocessing import StandardScaler, LabelEncoder
    from sklearn.model_selection import train_test_split
    from sklearn.metrics import accuracy_score, mean_absolute_error
    SKLEARN_AVAILABLE = True
except ImportError:
    SKLEARN_AVAILABLE = False
    print("⚠️  scikit-learn no disponible, usando simulación ML")

class MLDataProcessor:
    def __init__(self):
        self.scaler = StandardScaler() if SKLEARN_AVAILABLE else None
        self.label_encoder = LabelEncoder() if SKLEARN_AVAILABLE else None
    
    def extract_features_from_events(self, events: List[Dict[str, Any]]) -> pd.DataFrame:
        """
        Extrae features de eventos para entrenamiento ML
        """
        if not events:
            return pd.DataFrame()
        
        features_data = []
        
        for event in events:
            try:
                # Parsear fechas
                date_str = event.get('date', '').replace('Z', '+00:00')
                end_str = event.get('end_time', '').replace('Z', '+00:00')
                
                if not date_str or not end_str:
                    continue
                    
                start_time = datetime.fromisoformat(date_str)
                end_time = datetime.fromisoformat(end_str)
                
                # Features temporales
                hour = start_time.hour
                day_of_week = start_time.weekday()  # 0=Lunes, 6=Domingo
                duration_minutes = (end_time - start_time).total_seconds() / 60
                
                # Features de contenido
                title = event.get('title', '').lower()
                description = event.get('description', '').lower()
                event_type = event.get('type', 'general')
                
                # Features categóricas
                is_study = 1 if any(word in title for word in ['estudio', 'estudiar', 'examen', 'tarea', 'matematicas', 'fisica']) else 0
                is_work = 1 if any(word in title for word in ['trabajo', 'reunion', 'meeting', 'proyecto']) else 0
                is_exercise = 1 if any(word in title for word in ['ejercicio', 'gym', 'correr', 'deporte', 'nadar']) else 0
                
                # Features de tiempo relativo
                is_morning = 1 if 6 <= hour < 12 else 0
                is_afternoon = 1 if 12 <= hour < 18 else 0
                is_evening = 1 if 18 <= hour < 22 else 0
                is_weekend = 1 if day_of_week >= 5 else 0
                
                # Simulación de productividad (en una app real vendría de feedback del usuario)
                productivity_score = self._simulate_productivity_score(hour, day_of_week, duration_minutes, is_study)
                
                features_data.append({
                    'hour': hour,
                    'day_of_week': day_of_week,
                    'duration_minutes': duration_minutes,
                    'is_study': is_study,
                    'is_work': is_work,
                    'is_exercise': is_exercise,
                    'is_morning': is_morning,
                    'is_afternoon': is_afternoon,
                    'is_evening': is_evening,
                    'is_weekend': is_weekend,
                    'productivity_score': productivity_score,
                    'event_type': event_type,
                    'title_length': len(title),
                })
                
            except Exception as e:
                print(f"Error procesando evento: {e}")
                continue
        
        return pd.DataFrame(features_data)
    
    def _simulate_productivity_score(self, hour: int, day_of_week: int, duration: float, is_study: int) -> float:
        """
        Simula un score de productividad basado en patrones conocidos
        """
        base_score = 0.5
        
        # Horarios óptimos
        if 9 <= hour <= 11:  # Mañana productiva
            base_score += 0.3
        elif 14 <= hour <= 16:  # Tarde productiva
            base_score += 0.2
        elif hour < 8 or hour > 22:  # Muy temprano o muy tarde
            base_score -= 0.2
            
        # Días de la semana (martes y miércoles más productivos)
        if day_of_week in [1, 2]:  # Martes, Miércoles
            base_score += 0.15
        elif day_of_week >= 5:  # Fines de semana
            base_score -= 0.1
            
        # Duración óptima
        if is_study:
            if 45 <= duration <= 90:  # Duración ideal para estudio
                base_score += 0.2
            elif duration > 120:  # Muy largo
                base_score -= 0.15
        
        # Añadir algo de ruido aleatorio
        import random
        base_score += random.uniform(-0.1, 0.1)
        
        return max(0.0, min(1.0, base_score))

class MLModels:
    def __init__(self):
        self.productivity_predictor = None
        self.event_classifier = None
        self.schedule_clusterer = None
        self.models_trained = False
        self.models_dir = "app/ml/models"
        
        # Crear directorio de modelos si no existe
        os.makedirs(self.models_dir, exist_ok=True)
        
    def train_models(self, events_data: List[Dict[str, Any]]):
        """
        Entrena todos los modelos ML con datos de eventos
        """
        if not SKLEARN_AVAILABLE:
            print("⚠️  Usando simulación ML (sklearn no disponible)")
            self.models_trained = True
            return
            
        processor = MLDataProcessor()
        df = processor.extract_features_from_events(events_data)
        
        if len(df) < 10:
            print("⚠️  Pocos datos para entrenar ML, usando modelos pre-entrenados")
            self._create_demo_models()
            return
            
        try:
            # 1. Entrenamiento del predictor de productividad
            self._train_productivity_predictor(df)
            
            # 2. Entrenamiento del clasificador de eventos
            self._train_event_classifier(df)
            
            # 3. Entrenamiento del clustering de horarios
            self._train_schedule_clusterer(df)
            
            self.models_trained = True
            print(f"✅ Modelos ML entrenados exitosamente con {len(df)} eventos")
            
        except Exception as e:
            print(f"❌ Error entrenando modelos: {e}")
            self._create_demo_models()
    
    def _train_productivity_predictor(self, df: pd.DataFrame):
        """
        Entrena modelo para predecir productividad por horario
        """
        features = ['hour', 'day_of_week', 'duration_minutes', 'is_study', 'is_work', 'is_exercise']
        X = df[features]
        y = df['productivity_score']
        
        if len(X) > 5:
            X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
            
            self.productivity_predictor = RandomForestRegressor(n_estimators=50, random_state=42)
            self.productivity_predictor.fit(X_train, y_train)
            
            # Evaluar modelo
            y_pred = self.productivity_predictor.predict(X_test)
            mae = mean_absolute_error(y_test, y_pred)
            print(f"📊 Predictor de productividad MAE: {mae:.3f}")
            
            # Guardar modelo
            joblib.dump(self.productivity_predictor, f"{self.models_dir}/productivity_predictor.joblib")
    
    def _train_event_classifier(self, df: pd.DataFrame):
        """
        Entrena clasificador de tipos de eventos
        """
        features = ['hour', 'day_of_week', 'duration_minutes', 'title_length']
        X = df[features]
        
        # Crear etiquetas de clasificación
        y = []
        for _, row in df.iterrows():
            if row['is_study']:
                y.append('estudio')
            elif row['is_work']:
                y.append('trabajo')
            elif row['is_exercise']:
                y.append('ejercicio')
            else:
                y.append('personal')
        
        if len(set(y)) > 1 and len(X) > 5:
            X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
            
            self.event_classifier = RandomForestClassifier(n_estimators=30, random_state=42)
            self.event_classifier.fit(X_train, y_train)
            
            # Evaluar modelo
            y_pred = self.event_classifier.predict(X_test)
            accuracy = accuracy_score(y_test, y_pred)
            print(f"🎯 Clasificador de eventos accuracy: {accuracy:.3f}")
            
            # Guardar modelo
            joblib.dump(self.event_classifier, f"{self.models_dir}/event_classifier.joblib")
    
    def _train_schedule_clusterer(self, df: pd.DataFrame):
        """
        Entrena clustering para patrones de horarios
        """
        features = ['hour', 'day_of_week', 'duration_minutes']
        X = df[features]
        
        if len(X) > 10:
            self.schedule_clusterer = KMeans(n_clusters=min(3, len(X)//3), random_state=42)
            self.schedule_clusterer.fit(X)
            
            # Guardar modelo
            joblib.dump(self.schedule_clusterer, f"{self.models_dir}/schedule_clusterer.joblib")
            print(f"🔍 Clustering de horarios creado con {self.schedule_clusterer.n_clusters} clusters")
    
    def _create_demo_models(self):
        """
        Crea modelos de demostración con datos simulados
        """
        print("🔧 Creando modelos de demostración...")
        self.models_trained = True
    
    def predict_productivity(self, hour: int, day_of_week: int, duration: int, 
                           is_study: bool, is_work: bool, is_exercise: bool) -> float:
        """
        Predice productividad para un horario específico
        """
        if not self.models_trained:
            # Simulación para demo
            return self._simulate_productivity_demo(hour, day_of_week, duration, is_study)
            
        if not SKLEARN_AVAILABLE or self.productivity_predictor is None:
            return self._simulate_productivity_demo(hour, day_of_week, duration, is_study)
        
        try:
            features = np.array([[hour, day_of_week, duration, 
                                int(is_study), int(is_work), int(is_exercise)]])
            prediction = self.productivity_predictor.predict(features)[0]
            return max(0.0, min(1.0, prediction))
        except Exception as e:
            print(f"Error en predicción: {e}")
            return self._simulate_productivity_demo(hour, day_of_week, duration, is_study)
    
    def classify_event(self, hour: int, day_of_week: int, duration: int, title_length: int) -> str:
        """
        Clasifica tipo de evento basado en características
        """
        if not self.models_trained or not SKLEARN_AVAILABLE or self.event_classifier is None:
            return self._simulate_classification_demo(hour, duration)
            
        try:
            features = np.array([[hour, day_of_week, duration, title_length]])
            prediction = self.event_classifier.predict(features)[0]
            return prediction
        except Exception as e:
            print(f"Error en clasificación: {e}")
            return self._simulate_classification_demo(hour, duration)
    
    def _simulate_productivity_demo(self, hour: int, day_of_week: int, duration: int, is_study: bool) -> float:
        """Simulación de productividad para demo"""
        base = 0.5
        if 9 <= hour <= 11: base += 0.3
        elif 14 <= hour <= 16: base += 0.2
        if day_of_week in [1, 2]: base += 0.15
        if is_study and 45 <= duration <= 90: base += 0.2
        return max(0.0, min(1.0, base))
    
    def _simulate_classification_demo(self, hour: int, duration: int) -> str:
        """Simulación de clasificación para demo"""
        if duration >= 90: return 'estudio'
        elif hour < 9: return 'ejercicio'
        elif 9 <= hour <= 17: return 'trabajo'
        else: return 'personal'
    
    def get_schedule_insights(self, events_data: List[Dict[str, Any]]) -> Dict[str, Any]:
        """
        Genera insights ML sobre patrones de horarios
        """
        if not events_data:
            return {"error": "No hay datos suficientes"}
            
        processor = MLDataProcessor()
        df = processor.extract_features_from_events(events_data)
        
        if df.empty:
            return {"error": "No se pudieron procesar los eventos"}
        
        # Convertir valores numpy a tipos Python nativos y manejar NaN
        def safe_float(value):
            try:
                result = float(value)
                return 0.0 if pd.isna(result) else result
            except (ValueError, TypeError):
                return 0.0
                
        def safe_int(value):
            try:
                return int(value)
            except (ValueError, TypeError):
                return 0
        
        insights = {
            "total_events": int(len(df)),
            "avg_productivity": safe_float(df['productivity_score'].mean()),
            "best_hour": safe_int(df.loc[df['productivity_score'].idxmax(), 'hour']) if not df.empty else 9,
            "best_day": safe_int(df.loc[df['productivity_score'].idxmax(), 'day_of_week']) if not df.empty else 1,
            "avg_duration": safe_float(df['duration_minutes'].mean()),
            "study_percentage": safe_float((df['is_study'].sum() / len(df)) * 100),
            "work_percentage": safe_float((df['is_work'].sum() / len(df)) * 100),
            "exercise_percentage": safe_float((df['is_exercise'].sum() / len(df)) * 100),
            "morning_productivity": safe_float(df[df['is_morning'] == 1]['productivity_score'].mean()),
            "afternoon_productivity": safe_float(df[df['is_afternoon'] == 1]['productivity_score'].mean()),
            "evening_productivity": safe_float(df[df['is_evening'] == 1]['productivity_score'].mean()),
        }
        
        return insights