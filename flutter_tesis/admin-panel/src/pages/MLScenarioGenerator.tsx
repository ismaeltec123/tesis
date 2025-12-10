import { useState } from 'react'
import {
  Box,
  Paper,
  Typography,
  Button,
  TextField,
  Alert,
  CircularProgress,
  Stepper,
  Step,
  StepLabel,
  Card,
  CardContent,
  Grid,
  Chip,
  Divider
} from '@mui/material'
import {
  Psychology,
  CheckCircle,
  CloudSync
} from '@mui/icons-material'

interface ScenarioStats {
  total_events: number
  google_calendar_synced: number
  completado: number
  no_realizado: number
  postergado: number
  cancelado: number
  pendiente: number
  historyWeeks: number
  historyEvents: number
  futureWeeks: number
  futureEvents: number
  email: string
}

const steps = [
  'Autenticar Google',
  'Generar escenario',
  'Ver estadísticas',
  'Entrenar modelo'
]

export default function MLScenarioGenerator() {
  const [activeStep, setActiveStep] = useState(0)
  const [userEmail, setUserEmail] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [success, setSuccess] = useState<string | null>(null)
  const [stats, setStats] = useState<ScenarioStats | null>(null)
  const [isAuthenticated, setIsAuthenticated] = useState(false)

  const handleGoogleAuth = () => {
    // Abrir ventana de autenticación de Google
    window.open('http://localhost:8001/api/auth/google', '_blank')
    setSuccess('Por favor autoriza el acceso en la ventana que se abrió. Luego vuelve aquí e ingresa tu email.')
    setActiveStep(1)
    setIsAuthenticated(true)
  }

  const handleGenerateScenario = async () => {
    if (!userEmail) {
      setError('Por favor ingresa el email del usuario')
      return
    }

    setLoading(true)
    setError(null)
    setSuccess(null)
    setStats(null)

    try {
      const response = await fetch('http://localhost:8001/api/ml/generate-scenario', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          email: userEmail,
          history_weeks: 4,
          future_weeks: 2
        })
      })

      if (!response.ok) {
        const errorData = await response.json()
        throw new Error(errorData.detail || 'Error al generar escenario')
      }

      const result = await response.json()
      
      setStats({
        total_events: result.total_events,
        google_calendar_synced: result.google_calendar_synced,
        completado: result.by_status.completado || 0,
        no_realizado: result.by_status.no_realizado || 0,
        postergado: result.by_status.postergado || 0,
        cancelado: result.by_status.cancelado || 0,
        pendiente: result.by_status.pendiente || 0,
        historyWeeks: result.history.weeks,
        historyEvents: result.history.events,
        futureWeeks: result.future.weeks,
        futureEvents: result.future.events,
        email: result.email
      })

      setSuccess(`✅ Escenario creado: ${result.google_calendar_synced} eventos sincronizados con Google Calendar`)
      setActiveStep(2)
    } catch (err: any) {
      setError(err.message || 'Error al generar escenario')
    } finally {
      setLoading(false)
    }
  }

  const handleTrainModel = async () => {
    if (!userEmail || !stats) {
      setError('Primero debes generar el escenario')
      return
    }

    setLoading(true)
    setError(null)

    try {
      // Obtener eventos del backend
      const eventsResponse = await fetch(
        `http://localhost:8001/api/calendar/events?user_id=${encodeURIComponent(userEmail)}`
      )
      
      if (!eventsResponse.ok) {
        throw new Error('Error al obtener eventos')
      }

      const events = await eventsResponse.json()
      
      // Filtrar solo eventos históricos
      const historyEvents = events.filter((e: any) => 
        e.category === 'history' || new Date(e.date) < new Date()
      )

      // Entrenar modelo
      const trainResponse = await fetch('http://localhost:5000/train', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          user_id: userEmail,
          events: historyEvents
        }),
      })

      if (!trainResponse.ok) {
        throw new Error('Error al entrenar modelo')
      }

      const result = await trainResponse.json()
      setSuccess(`✅ Modelo entrenado: ${result.total_events} eventos, ${result.weeks_of_data.toFixed(1)} semanas`)
      setActiveStep(3)
    } catch (err: any) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  return (
    <Box>
      <Paper sx={{ p: 3 }}>
        <Box display="flex" alignItems="center" mb={3}>
          <Psychology sx={{ fontSize: 40, mr: 2, color: 'primary.main' }} />
          <Box>
            <Typography variant="h4">Generador de Escenario ML</Typography>
            <Typography variant="body2" color="text.secondary">
              Vincula Google Calendar y genera datos de entrenamiento realistas
            </Typography>
          </Box>
        </Box>

        <Stepper activeStep={activeStep} sx={{ mb: 4 }}>
          {steps.map((label) => (
            <Step key={label}>
              <StepLabel>{label}</StepLabel>
            </Step>
          ))}
        </Stepper>

        {error && (
          <Alert severity="error" sx={{ mb: 3 }} onClose={() => setError(null)}>
            {error}
          </Alert>
        )}

        {success && (
          <Alert severity="success" sx={{ mb: 3 }} onClose={() => setSuccess(null)}>
            {success}
          </Alert>
        )}

        {/* PASO 1: AUTENTICACIÓN */}
        {activeStep === 0 && (
          <Card sx={{ mb: 3 }}>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                🔐 Paso 1: Autenticación con Google Calendar
              </Typography>
              <Alert severity="warning" sx={{ mb: 2 }}>
                <strong>⚠️ IMPORTANTE:</strong> Debes autenticarte primero con Google Calendar
                <br />
                El sistema creará eventos reales en tu calendario de Google
              </Alert>
              <Button
                variant="contained"
                size="large"
                onClick={handleGoogleAuth}
                startIcon={<CloudSync />}
                fullWidth
                sx={{ py: 2 }}
              >
                🔓 Iniciar Sesión con Google Calendar
              </Button>
            </CardContent>
          </Card>
        )}

        {/* PASO 2: GENERAR ESCENARIO */}
        {activeStep >= 1 && (
          <Card sx={{ mb: 3 }}>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                📧 Usuario con Google Calendar
              </Typography>
              <TextField
                fullWidth
                label="Email del usuario"
                value={userEmail}
                onChange={(e) => setUserEmail(e.target.value)}
                placeholder="ismael.quispe@tecsup.edu.pe"
                helperText="Usa el mismo email con el que te autenticaste"
                sx={{ mb: 2 }}
              />
              
              <Alert severity="info" icon={<CloudSync />}>
                <strong>Sistema vinculado a Google Calendar:</strong>
                <br />
                • Se crearán eventos directamente en tu Google Calendar
                <br />
                • Se sincronizarán automáticamente con la app Flutter
                <br />
                • <strong>📚 HISTORIAL:</strong> 4 semanas pasadas (~60 eventos con estados variados)
                <br />
                • <strong>📅 FUTURO:</strong> 2 semanas adelante (~30 eventos pendientes)
                <br />
                • <strong>Total:</strong> ~90 eventos listos para ML
              </Alert>

              <Box sx={{ mt: 3 }}>
                <Button
                  variant="contained"
                  size="large"
                  onClick={handleGenerateScenario}
                  disabled={loading || !userEmail}
                  startIcon={loading ? <CircularProgress size={20} /> : <CheckCircle />}
                  fullWidth
                >
                  {loading ? 'Generando en Google Calendar...' : 'GENERAR ESCENARIO COMPLETO'}
                </Button>
              </Box>
            </CardContent>
          </Card>
        )}

        {/* PASO 3: ESTADÍSTICAS */}
        {stats && (
          <>
            <Card sx={{ mb: 3 }}>
              <CardContent>
                <Typography variant="h6" gutterBottom>
                  📊 Estadísticas del Escenario
                </Typography>
                <Divider sx={{ mb: 2 }} />
                <Grid container spacing={2}>
                  <Grid item xs={12} sm={4}>
                    <Chip
                      label={`Total: ${stats.total_events} eventos`}
                      color="primary"
                      sx={{ width: '100%', height: 'auto', py: 1 }}
                    />
                  </Grid>
                  <Grid item xs={12} sm={4}>
                    <Chip
                      label={`🔗 Google: ${stats.google_calendar_synced} sincronizados`}
                      color="success"
                      sx={{ width: '100%', height: 'auto', py: 1 }}
                    />
                  </Grid>
                  <Grid item xs={12} sm={4}>
                    <Chip
                      label={`👤 ${stats.email}`}
                      color="info"
                      sx={{ width: '100%', height: 'auto', py: 1 }}
                    />
                  </Grid>
                  <Grid item xs={12} sm={6}>
                    <Chip
                      label={`📚 Historial: ${stats.historyEvents} eventos (${stats.historyWeeks} semanas)`}
                      sx={{ width: '100%', height: 'auto', py: 1 }}
                    />
                  </Grid>
                  <Grid item xs={12} sm={6}>
                    <Chip
                      label={`📅 Futuro: ${stats.futureEvents} eventos (${stats.futureWeeks} semanas)`}
                      sx={{ width: '100%', height: 'auto', py: 1 }}
                    />
                  </Grid>
                  <Grid item xs={6} sm={4}>
                    <Chip
                      label={`✅ Completado: ${stats.completado}`}
                      color="success"
                      variant="outlined"
                      sx={{ width: '100%' }}
                    />
                  </Grid>
                  <Grid item xs={6} sm={4}>
                    <Chip
                      label={`⏳ Pendiente: ${stats.pendiente}`}
                      color="info"
                      variant="outlined"
                      sx={{ width: '100%' }}
                    />
                  </Grid>
                  <Grid item xs={6} sm={4}>
                    <Chip
                      label={`❌ No realizado: ${stats.no_realizado}`}
                      color="error"
                      variant="outlined"
                      sx={{ width: '100%' }}
                    />
                  </Grid>
                  <Grid item xs={6} sm={4}>
                    <Chip
                      label={`📌 Postergado: ${stats.postergado}`}
                      color="warning"
                      variant="outlined"
                      sx={{ width: '100%' }}
                    />
                  </Grid>
                  <Grid item xs={6} sm={4}>
                    <Chip
                      label={`🚫 Cancelado: ${stats.cancelado}`}
                      color="default"
                      variant="outlined"
                      sx={{ width: '100%' }}
                    />
                  </Grid>
                </Grid>
              </CardContent>
            </Card>

            <Card>
              <CardContent>
                <Typography variant="h6" gutterBottom>
                  🤖 Entrenar Modelo ML
                </Typography>
                <Alert severity="success" sx={{ mb: 2 }}>
                  ✅ Escenario generado y sincronizado con Google Calendar
                  <br />
                  Ahora puedes entrenar el modelo con estos datos
                </Alert>
                <Button
                  variant="contained"
                  color="secondary"
                  size="large"
                  onClick={handleTrainModel}
                  disabled={loading}
                  startIcon={loading ? <CircularProgress size={20} /> : <Psychology />}
                  fullWidth
                >
                  {loading ? 'Entrenando...' : 'Entrenar Modelo ML'}
                </Button>
              </CardContent>
            </Card>
          </>
        )}
      </Paper>
    </Box>
  )
}
