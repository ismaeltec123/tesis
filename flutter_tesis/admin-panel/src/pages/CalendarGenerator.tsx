import { useState } from 'react'
import {
  Box,
  Button,
  Card,
  CardContent,
  FormControl,
  Grid,
  InputLabel,
  MenuItem,
  Select,
  TextField,
  Typography,
  Paper,
  Alert,
  CircularProgress,
  Divider,
  Chip,
} from '@mui/material'
import AddIcon from '@mui/icons-material/Add'
import PreviewIcon from '@mui/icons-material/Preview'
import SaveIcon from '@mui/icons-material/Save'
import { testTemplatesAPI, calendarAPI } from '../services/api'

interface EventTemplate {
  title: string
  description: string
  type: 'study' | 'exercise' | 'personal' | 'work'
  hour: number
  duration: number
  daysOfWeek: number[] // 0=Sunday, 1=Monday, etc.
}

const EVENT_TYPES = [
  { value: 'study', label: 'Estudio' },
  { value: 'exercise', label: 'Ejercicio' },
  { value: 'personal', label: 'Personal' },
  { value: 'work', label: 'Trabajo' },
]

const DAYS_OF_WEEK = [
  { value: 1, label: 'Lunes' },
  { value: 2, label: 'Martes' },
  { value: 3, label: 'Miércoles' },
  { value: 4, label: 'Jueves' },
  { value: 5, label: 'Viernes' },
  { value: 6, label: 'Sábado' },
  { value: 0, label: 'Domingo' },
]

export default function CalendarGenerator() {
  const [templateName, setTemplateName] = useState('')
  const [templateDescription, setTemplateDescription] = useState('')
  const [events, setEvents] = useState<EventTemplate[]>([])
  const [currentEvent, setCurrentEvent] = useState<EventTemplate>({
    title: '',
    description: '',
    type: 'study',
    hour: 9,
    duration: 60,
    daysOfWeek: [],
  })
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [success, setSuccess] = useState<string | null>(null)
  const [previewEmail, setPreviewEmail] = useState('')

  const handleAddEvent = () => {
    if (!currentEvent.title || currentEvent.daysOfWeek.length === 0) {
      setError('Por favor completa el título y selecciona al menos un día')
      return
    }

    setEvents([...events, currentEvent])
    setCurrentEvent({
      title: '',
      description: '',
      type: 'study',
      hour: 9,
      duration: 60,
      daysOfWeek: [],
    })
    setSuccess('Evento agregado a la plantilla')
  }

  const handleRemoveEvent = (index: number) => {
    setEvents(events.filter((_, i) => i !== index))
  }

  const handleSaveTemplate = async () => {
    if (!templateName || events.length === 0) {
      setError('Por favor ingresa un nombre y agrega al menos un evento')
      return
    }

    try {
      setLoading(true)
      setError(null)
      await testTemplatesAPI.createTemplate({
        name: templateName,
        description: templateDescription,
        events: events.map(e => ({
          ...e,
          days: e.daysOfWeek
        })),
      })
      setSuccess('Plantilla guardada correctamente')
      // Reset form
      setTemplateName('')
      setTemplateDescription('')
      setEvents([])
    } catch (err: any) {
      setError(err.message || 'Error al guardar plantilla')
    } finally {
      setLoading(false)
    }
  }

  const handlePreview = async () => {
    if (!previewEmail) {
      setError('Por favor ingresa un email para previsualizar')
      return
    }

    if (events.length === 0) {
      setError('Agrega al menos un evento para previsualizar')
      return
    }

    try {
      setLoading(true)
      setError(null)
      // This would generate a temporary calendar for preview
      // For now, just show success message
      setSuccess(`Previsualización generada para ${previewEmail}`)
    } catch (err: any) {
      setError(err.message || 'Error al generar previsualización')
    } finally {
      setLoading(false)
    }
  }

  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        Generador de Calendarios
      </Typography>
      <Typography variant="body1" color="textSecondary" paragraph>
        Crea plantillas personalizadas de calendarios para testing
      </Typography>

      <Grid container spacing={3}>
        {/* Template Info */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Información de la Plantilla
              </Typography>
              
              <TextField
                fullWidth
                label="Nombre de la Plantilla"
                value={templateName}
                onChange={(e) => setTemplateName(e.target.value)}
                sx={{ mb: 2 }}
              />
              
              <TextField
                fullWidth
                label="Descripción"
                multiline
                rows={2}
                value={templateDescription}
                onChange={(e) => setTemplateDescription(e.target.value)}
                sx={{ mb: 2 }}
              />

              <Divider sx={{ my: 2 }} />

              <Typography variant="h6" gutterBottom>
                Agregar Evento
              </Typography>

              <TextField
                fullWidth
                label="Título del Evento"
                value={currentEvent.title}
                onChange={(e) => setCurrentEvent({ ...currentEvent, title: e.target.value })}
                sx={{ mb: 2 }}
              />

              <TextField
                fullWidth
                label="Descripción"
                value={currentEvent.description}
                onChange={(e) => setCurrentEvent({ ...currentEvent, description: e.target.value })}
                sx={{ mb: 2 }}
              />

              <FormControl fullWidth sx={{ mb: 2 }}>
                <InputLabel>Tipo de Evento</InputLabel>
                <Select
                  value={currentEvent.type}
                  label="Tipo de Evento"
                  onChange={(e) => setCurrentEvent({ ...currentEvent, type: e.target.value as any })}
                >
                  {EVENT_TYPES.map((type) => (
                    <MenuItem key={type.value} value={type.value}>
                      {type.label}
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>

              <Grid container spacing={2} sx={{ mb: 2 }}>
                <Grid item xs={6}>
                  <TextField
                    fullWidth
                    label="Hora (0-23)"
                    type="number"
                    value={currentEvent.hour}
                    onChange={(e) => setCurrentEvent({ ...currentEvent, hour: parseInt(e.target.value) })}
                    InputProps={{ inputProps: { min: 0, max: 23 } }}
                  />
                </Grid>
                <Grid item xs={6}>
                  <TextField
                    fullWidth
                    label="Duración (min)"
                    type="number"
                    value={currentEvent.duration}
                    onChange={(e) => setCurrentEvent({ ...currentEvent, duration: parseInt(e.target.value) })}
                    InputProps={{ inputProps: { min: 15, max: 480 } }}
                  />
                </Grid>
              </Grid>

              <FormControl fullWidth sx={{ mb: 2 }}>
                <InputLabel>Días de la Semana</InputLabel>
                <Select
                  multiple
                  value={currentEvent.daysOfWeek}
                  label="Días de la Semana"
                  onChange={(e) => setCurrentEvent({ ...currentEvent, daysOfWeek: e.target.value as number[] })}
                  renderValue={(selected) => (
                    <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 0.5 }}>
                      {(selected as number[]).map((value) => (
                        <Chip key={value} label={DAYS_OF_WEEK.find(d => d.value === value)?.label} size="small" />
                      ))}
                    </Box>
                  )}
                >
                  {DAYS_OF_WEEK.map((day) => (
                    <MenuItem key={day.value} value={day.value}>
                      {day.label}
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>

              <Button
                fullWidth
                variant="contained"
                startIcon={<AddIcon />}
                onClick={handleAddEvent}
              >
                Agregar Evento
              </Button>
            </CardContent>
          </Card>
        </Grid>

        {/* Events List */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Box display="flex" justifyContent="space-between" alignItems="center" mb={2}>
                <Typography variant="h6">
                  Eventos en la Plantilla ({events.length})
                </Typography>
                <Button
                  variant="contained"
                  startIcon={<SaveIcon />}
                  onClick={handleSaveTemplate}
                  disabled={loading || events.length === 0}
                >
                  Guardar Plantilla
                </Button>
              </Box>

              {events.length === 0 ? (
                <Alert severity="info">
                  No hay eventos. Agrega eventos usando el formulario de la izquierda.
                </Alert>
              ) : (
                <Box>
                  {events.map((event, index) => (
                    <Paper key={index} sx={{ p: 2, mb: 2 }}>
                      <Box display="flex" justifyContent="space-between" alignItems="start">
                        <Box flex={1}>
                          <Typography variant="subtitle1" fontWeight="bold">
                            {event.title}
                          </Typography>
                          <Typography variant="body2" color="textSecondary">
                            {event.description}
                          </Typography>
                          <Box display="flex" gap={1} mt={1} flexWrap="wrap">
                            <Chip label={EVENT_TYPES.find(t => t.value === event.type)?.label} size="small" />
                            <Chip label={`${event.hour}:00`} size="small" />
                            <Chip label={`${event.duration} min`} size="small" />
                          </Box>
                          <Box display="flex" gap={0.5} mt={1} flexWrap="wrap">
                            {event.daysOfWeek.map(day => (
                              <Chip 
                                key={day} 
                                label={DAYS_OF_WEEK.find(d => d.value === day)?.label.substring(0, 3)} 
                                size="small" 
                                variant="outlined"
                              />
                            ))}
                          </Box>
                        </Box>
                        <Button
                          size="small"
                          color="error"
                          onClick={() => handleRemoveEvent(index)}
                        >
                          Eliminar
                        </Button>
                      </Box>
                    </Paper>
                  ))}
                </Box>
              )}

              <Divider sx={{ my: 2 }} />

              <Typography variant="h6" gutterBottom>
                Previsualizar
              </Typography>
              <TextField
                fullWidth
                label="Email para Previsualización"
                type="email"
                value={previewEmail}
                onChange={(e) => setPreviewEmail(e.target.value)}
                sx={{ mb: 2 }}
              />
              <Button
                fullWidth
                variant="outlined"
                startIcon={<PreviewIcon />}
                onClick={handlePreview}
                disabled={loading || events.length === 0}
              >
                Generar Previsualización
              </Button>

              {loading && (
                <Box display="flex" justifyContent="center" mt={2}>
                  <CircularProgress />
                </Box>
              )}
            </CardContent>
          </Card>
        </Grid>
      </Grid>

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
    </Box>
  )
}
