import { useState, useEffect } from 'react'
import {
  Box,
  Button,
  Card,
  CardContent,
  FormControl,
  InputLabel,
  MenuItem,
  Select,
  TextField,
  Typography,
  Alert,
  CircularProgress,
  Paper,
  Divider,
  Autocomplete,
} from '@mui/material'
import PlayArrowIcon from '@mui/icons-material/PlayArrow'
import DeleteIcon from '@mui/icons-material/Delete'
import SyncIcon from '@mui/icons-material/Sync'
import LinkOffIcon from '@mui/icons-material/LinkOff'
import { calendarAPI, adminAPI } from '../services/api'

interface Template {
  id: string
  name: string
  description: string
  eventCount: number
}

const PREDEFINED_TEMPLATES: Template[] = [
  { 
    id: 'full', 
    name: 'Horario Completo', 
    description: '20+ eventos, todos los días cubiertos',
    eventCount: 25
  },
  { 
    id: 'partial', 
    name: 'Horario Parcial', 
    description: '10 eventos, algunos gaps',
    eventCount: 10
  },
  { 
    id: 'empty', 
    name: 'Horario Vacío', 
    description: '0-2 eventos',
    eventCount: 2
  },
  { 
    id: 'study-focused', 
    name: 'Enfocado en Estudio', 
    description: 'Principalmente eventos académicos',
    eventCount: 15
  },
  { 
    id: 'exercise-focused', 
    name: 'Enfocado en Ejercicio', 
    description: 'Principalmente eventos deportivos',
    eventCount: 12
  },
]

export default function TestEnvironment() {
  const [userEmail, setUserEmail] = useState('')
  const [selectedTemplate, setSelectedTemplate] = useState('')
  const [selectedDuration, setSelectedDuration] = useState('1month')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [success, setSuccess] = useState<string | null>(null)
  const [users, setUsers] = useState<any[]>([])
  const [loadingUsers, setLoadingUsers] = useState(true)

  // Cargar usuarios al montar el componente
  useEffect(() => {
    loadUsers()
  }, [])

  const loadUsers = async () => {
    try {
      setLoadingUsers(true)
      const usersList = await adminAPI.getUsers()
      setUsers(usersList)
    } catch (err) {
      console.error('Error loading users:', err)
    } finally {
      setLoadingUsers(false)
    }
  }

  const handleGenerateCalendar = async () => {
    if (!userEmail || !selectedTemplate) {
      setError('Por favor ingresa un email y selecciona una plantilla')
      return
    }

    try {
      setLoading(true)
      setError(null)
      const result = await calendarAPI.generateCalendar(userEmail, selectedTemplate, selectedDuration)
      setSuccess(`${result.message}. ${result.info || ''}`)
    } catch (err: any) {
      setError(err.message || 'Error al generar calendario')
    } finally {
      setLoading(false)
    }
  }

  const handleClearEvents = async () => {
    if (!userEmail) {
      setError('Por favor ingresa un email')
      return
    }

    if (!window.confirm(`¿Estás seguro de eliminar todos los eventos de ${userEmail}?`)) {
      return
    }

    try {
      setLoading(true)
      setError(null)
      await calendarAPI.deleteAllUserEvents(userEmail)
      setSuccess('Eventos eliminados correctamente')
    } catch (err: any) {
      setError(err.message || 'Error al eliminar eventos')
    } finally {
      setLoading(false)
    }
  }

  const handleSyncWithGoogle = async () => {
    if (!userEmail) {
      setError('Por favor ingresa un email')
      return
    }

    try {
      setLoading(true)
      setError(null)
      await calendarAPI.syncWithGoogle(userEmail)
      setSuccess('Sincronización con Google Calendar completada')
    } catch (err: any) {
      setError(err.message || 'Error al sincronizar con Google Calendar')
    } finally {
      setLoading(false)
    }
  }

  const handleRemoveGoogleToken = async () => {
    if (!window.confirm('¿Estás seguro de eliminar el token de Google? Tendrás que volver a autenticarte.')) {
      return
    }

    try {
      setLoading(true)
      setError(null)
      await adminAPI.removeGoogleToken()
      setSuccess('Token de Google eliminado exitosamente.')
    } catch (err: any) {
      setError(err.message || 'Error al eliminar token de Google')
    } finally {
      setLoading(false)
    }
  }

  const handleAuthenticateGoogle = async () => {
    try {
      setLoading(true)
      setError(null)
      const response = await adminAPI.authenticateGoogleAuto()
      if (response.auth_url) {
        window.open(response.auth_url, '_blank')
        setSuccess('Ventana de autenticación abierta. Selecciona tu cuenta de Gmail y autoriza la aplicación.')
      }
    } catch (err: any) {
      setError(err.message || 'Error al iniciar autenticación de Google')
    } finally {
      setLoading(false)
    }
  }

  const handleDeleteAllEventsDangerous = async () => {
    setError(null) // Limpiar errores previos
    
    // Confirmación nivel 1
    const firstConfirm = window.confirm(
      '⚠️ ADVERTENCIA CRÍTICA ⚠️\n\n' +
      'Esta acción eliminará:\n' +
      '• TODOS los eventos de Google Calendar (datos externos)\n' +
      '• TODOS los eventos de la base de datos local\n\n' +
      '❌ ESTA ACCIÓN NO SE PUEDE DESHACER\n\n' +
      '¿Estás ABSOLUTAMENTE SEGURO?'
    )
    
    if (!firstConfirm) {
      // Usuario canceló, no mostrar error
      return
    }

    // Confirmación nivel 2
    const confirmation = window.prompt(
      '🔴 CONFIRMACIÓN FINAL 🔴\n\n' +
      'Para confirmar, escribe exactamente:\nBORRAR TODO'
    )

    // Si cancela (null) o escribe mal
    if (confirmation === null) {
      // Usuario canceló, no mostrar error
      return
    }

    if (confirmation.trim() !== 'BORRAR TODO') {
      setError(`Texto incorrecto. Escribiste: "${confirmation}". Debes escribir exactamente: "BORRAR TODO"`)
      return
    }

    try {
      setLoading(true)
      setError(null)
      const result = await adminAPI.deleteAllEventsDangerous()
      
      setSuccess(
        `⚠️ ELIMINACIÓN COMPLETADA:\n` +
        `• Google Calendar: ${result.deleted_google} eventos\n` +
        `• Base de datos: ${result.deleted_local} eventos` +
        (result.errors?.length > 0 ? `\n⚠️ ${result.errors.length} errores encontrados` : '')
      )
    } catch (err: any) {
      setError(err.message || 'Error al eliminar todos los eventos')
    } finally {
      setLoading(false)
    }
  }

  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        Entorno de Pruebas
      </Typography>
      <Typography variant="body1" color="textSecondary" paragraph>
        Genera calendarios de prueba y prueba funcionalidades del sistema
      </Typography>

      <Card sx={{ mb: 3 }}>
        <CardContent>
          <Alert severity="error" sx={{ mb: 3 }}>
            <Typography variant="subtitle2" fontWeight="bold" gutterBottom>
              ⚠️ ZONA PELIGROSA - Solo para Desarrollo
            </Typography>
            <Typography variant="body2">
              El botón "BORRAR TODO" elimina TODOS los eventos de Google Calendar (datos externos) 
              y la base de datos local. Esta acción NO SE PUEDE DESHACER.
            </Typography>
          </Alert>

          <Typography variant="h6" gutterBottom>
            Configuración de Usuario de Prueba
          </Typography>
          
          <Autocomplete
            freeSolo
            options={users.map((user) => user.email)}
            value={userEmail}
            onChange={(event, newValue) => {
              setUserEmail(newValue || '')
            }}
            onInputChange={(event, newValue) => {
              setUserEmail(newValue)
            }}
            loading={loadingUsers}
            renderInput={(params) => (
              <TextField
                {...params}
                fullWidth
                label="Email del Usuario"
                type="email"
                placeholder="Selecciona o escribe un email"
                sx={{ mb: 2 }}
                helperText="Selecciona un usuario existente o escribe un nuevo email"
              />
            )}
          />

          <FormControl fullWidth sx={{ mb: 3 }}>
            <InputLabel>Plantilla de Calendario</InputLabel>
            <Select
              value={selectedTemplate}
              label="Plantilla de Calendario"
              onChange={(e) => setSelectedTemplate(e.target.value)}
            >
              {PREDEFINED_TEMPLATES.map((template) => (
                <MenuItem key={template.id} value={template.id}>
                  {template.name} - {template.description}
                </MenuItem>
              ))}
            </Select>
          </FormControl>

          <FormControl fullWidth sx={{ mb: 3 }}>
            <InputLabel>Duración del Calendario</InputLabel>
            <Select
              value={selectedDuration}
              label="Duración del Calendario"
              onChange={(e) => setSelectedDuration(e.target.value)}
            >
              <MenuItem value="1week">1 Semana (7 días)</MenuItem>
              <MenuItem value="1month">1 Mes (30 días)</MenuItem>
              <MenuItem value="3months">3 Meses (90 días)</MenuItem>
              <MenuItem value="6months">6 Meses (180 días)</MenuItem>
            </Select>
          </FormControl>

          <Box display="flex" gap={2} flexWrap="wrap">
            <Button
              variant="contained"
              startIcon={<PlayArrowIcon />}
              onClick={handleGenerateCalendar}
              disabled={loading || !userEmail || !selectedTemplate}
            >
              Generar Calendario
            </Button>
            <Button
              variant="outlined"
              startIcon={<DeleteIcon />}
              onClick={handleClearEvents}
              disabled={loading || !userEmail}
              color="error"
            >
              Limpiar Eventos
            </Button>
            <Button
              variant="outlined"
              startIcon={<SyncIcon />}
              onClick={handleSyncWithGoogle}
              disabled={loading || !userEmail}
            >
              Sincronizar con Google
            </Button>
            <Button
              variant="contained"
              startIcon={<SyncIcon />}
              onClick={handleAuthenticateGoogle}
              disabled={loading}
              color="success"
            >
              Conectar Google Calendar
            </Button>
            <Button
              variant="outlined"
              startIcon={<LinkOffIcon />}
              onClick={handleRemoveGoogleToken}
              disabled={loading}
              color="warning"
            >
              Eliminar Token Google
            </Button>
            <Button
              variant="contained"
              startIcon={<DeleteIcon />}
              onClick={handleDeleteAllEventsDangerous}
              disabled={loading}
              color="error"
              sx={{ 
                backgroundColor: '#d32f2f',
                '&:hover': { backgroundColor: '#b71c1c' }
              }}
            >
              ⚠️ BORRAR TODO (Google + BD)
            </Button>
          </Box>

          {loading && (
            <Box display="flex" justifyContent="center" mt={3}>
              <CircularProgress />
            </Box>
          )}

          {error && (
            <Alert severity="error" sx={{ mt: 2 }} onClose={() => setError(null)}>
              {error}
            </Alert>
          )}

          {success && (
            <Alert severity="success" sx={{ mt: 2 }} onClose={() => setSuccess(null)}>
              {success}
            </Alert>
          )}
        </CardContent>
      </Card>

      <Paper sx={{ p: 3 }}>
        <Typography variant="h6" gutterBottom>
          Plantillas Disponibles
        </Typography>
        <Divider sx={{ mb: 2 }} />
        {PREDEFINED_TEMPLATES.map((template) => (
          <Box key={template.id} sx={{ mb: 2 }}>
            <Typography variant="subtitle1" fontWeight="bold">
              {template.name}
            </Typography>
            <Typography variant="body2" color="textSecondary">
              {template.description} ({template.eventCount} eventos)
            </Typography>
          </Box>
        ))}
      </Paper>
    </Box>
  )
}
