"""
Model Manager - Gestiona almacenamiento y carga de modelos Prophet
"""
import os
import joblib
import json
from datetime import datetime
from typing import Tuple, Optional, List, Dict

class ModelManager:
    """
    Gestiona persistencia de modelos Prophet en disco
    """
    
    def __init__(self, models_dir: str = 'models'):
        self.models_dir = models_dir
        self._ensure_models_dir()
    
    def _ensure_models_dir(self):
        """Crea directorio de modelos si no existe"""
        if not os.path.exists(self.models_dir):
            os.makedirs(self.models_dir)
            print(f"📁 Created models directory: {self.models_dir}")
    
    def save_model(self, user_id: str, model, metadata: dict) -> bool:
        """
        Guarda modelo Prophet y sus metadatos
        
        Args:
            user_id: ID del usuario
            model: Modelo Prophet entrenado
            metadata: Diccionario con información del entrenamiento
        
        Returns:
            bool: True si se guardó exitosamente
        """
        try:
            model_path = self._get_model_path(user_id)
            metadata_path = self._get_metadata_path(user_id)
            
            # Guardar modelo con joblib
            joblib.dump(model, model_path)
            
            # Guardar metadata como JSON
            with open(metadata_path, 'w', encoding='utf-8') as f:
                json.dump(metadata, f, indent=2, ensure_ascii=False)
            
            print(f"   💾 Model saved: {model_path}")
            return True
            
        except Exception as e:
            print(f"   ❌ Error saving model for user {user_id}: {e}")
            return False
    
    def load_model(self, user_id: str) -> Tuple[Optional[any], Optional[dict]]:
        """
        Carga modelo Prophet y sus metadatos
        
        Returns:
            (model, metadata) o (None, None) si no existe
        """
        try:
            model_path = self._get_model_path(user_id)
            metadata_path = self._get_metadata_path(user_id)
            
            if not os.path.exists(model_path):
                print(f"   ⚠️  Model not found for user {user_id}")
                return None, None
            
            # Cargar modelo
            model = joblib.load(model_path)
            
            # Cargar metadata
            metadata = {}
            if os.path.exists(metadata_path):
                with open(metadata_path, 'r', encoding='utf-8') as f:
                    metadata = json.load(f)
            
            print(f"   📥 Model loaded: {model_path}")
            return model, metadata
            
        except Exception as e:
            print(f"   ❌ Error loading model for user {user_id}: {e}")
            return None, None
    
    def model_exists(self, user_id: str) -> bool:
        """Verifica si existe modelo para el usuario"""
        model_path = self._get_model_path(user_id)
        return os.path.exists(model_path)
    
    def get_metadata(self, user_id: str) -> dict:
        """Obtiene solo los metadatos del modelo"""
        metadata_path = self._get_metadata_path(user_id)
        
        if not os.path.exists(metadata_path):
            return {}
        
        try:
            with open(metadata_path, 'r', encoding='utf-8') as f:
                return json.load(f)
        except:
            return {}
    
    def delete_model(self, user_id: str) -> bool:
        """Elimina modelo y metadatos de un usuario"""
        try:
            model_path = self._get_model_path(user_id)
            metadata_path = self._get_metadata_path(user_id)
            
            deleted = False
            
            if os.path.exists(model_path):
                os.remove(model_path)
                deleted = True
            
            if os.path.exists(metadata_path):
                os.remove(metadata_path)
            
            if deleted:
                print(f"   🗑️  Model deleted for user {user_id}")
            
            return deleted
            
        except Exception as e:
            print(f"   ❌ Error deleting model for user {user_id}: {e}")
            return False
    
    def list_all_models(self) -> List[Dict]:
        """
        Lista todos los modelos guardados
        
        Returns:
            Lista de diccionarios con info de cada modelo
        """
        models = []
        
        if not os.path.exists(self.models_dir):
            return models
        
        for filename in os.listdir(self.models_dir):
            if filename.startswith('user_') and filename.endswith('.pkl'):
                # Extraer user_id del nombre del archivo
                user_id = filename.replace('user_', '').replace('.pkl', '')
                
                model_path = os.path.join(self.models_dir, filename)
                file_size_mb = os.path.getsize(model_path) / (1024 * 1024)
                
                metadata = self.get_metadata(user_id)
                
                models.append({
                    'user_id': user_id,
                    'model_path': model_path,
                    'size_mb': round(file_size_mb, 2),
                    'trained_at': metadata.get('trained_at', 'unknown'),
                    'events_count': metadata.get('events_count', 0),
                    'weeks_of_data': metadata.get('weeks_of_data', 0)
                })
        
        return models
    
    def _get_model_path(self, user_id: str) -> str:
        """Genera ruta del archivo del modelo"""
        return os.path.join(self.models_dir, f'user_{user_id}.pkl')
    
    def _get_metadata_path(self, user_id: str) -> str:
        """Genera ruta del archivo de metadatos"""
        return os.path.join(self.models_dir, f'user_{user_id}_metadata.json')
