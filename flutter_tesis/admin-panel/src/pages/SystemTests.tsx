import { useState } from 'react'
import {
  Box,
  Button,
  Card,
  CardContent,
  Typography,
  Paper,
  CircularProgress,
  Alert,
  Divider,
  Chip,
} from '@mui/material'
import PlayArrowIcon from '@mui/icons-material/PlayArrow'
import CheckCircleIcon from '@mui/icons-material/CheckCircle'
import ErrorIcon from '@mui/icons-material/Error'
import { systemTestsAPI } from '../services/api'

interface TestResult {
  name: string
  passed: boolean
  duration: number
  message?: string
  details?: any
}

export default function SystemTests() {
  const [loading, setLoading] = useState(false)
  const [testResults, setTestResults] = useState<TestResult[]>([])
  const [error, setError] = useState<string | null>(null)

  const runTest = async (testName: string, testFn: () => Promise<any>) => {
    const startTime = Date.now()
    try {
      const result = await testFn()
      const duration = Date.now() - startTime
      return {
        name: testName,
        passed: true,
        duration,
        details: result,
      }
    } catch (err: any) {
      const duration = Date.now() - startTime
      return {
        name: testName,
        passed: false,
        duration,
        message: err.message || 'Error desconocido',
      }
    }
  }

  const handleTestHabitML = async () => {
    setLoading(true)
    setError(null)
    try {
      const result = await runTest('Sistema ML de Hábitos', systemTestsAPI.testHabitML)
      setTestResults([result])
    } catch (err: any) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  const handleTestNotifications = async () => {
    setLoading(true)
    setError(null)
    try {
      const result = await runTest('Notificaciones Pre-Evento', systemTestsAPI.testNotifications)
      setTestResults([result])
    } catch (err: any) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  const handleTestEnhancedAI = async () => {
    setLoading(true)
    setError(null)
    try {
      const result = await runTest('Enhanced AI', systemTestsAPI.testEnhancedAI)
      setTestResults([result])
    } catch (err: any) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  const handleRunAllTests = async () => {
    setLoading(true)
    setError(null)
    setTestResults([])
    
    try {
      const results = await Promise.all([
        runTest('Sistema ML de Hábitos', systemTestsAPI.testHabitML),
        runTest('Notificaciones Pre-Evento', systemTestsAPI.testNotifications),
        runTest('Enhanced AI', systemTestsAPI.testEnhancedAI),
      ])
      setTestResults(results)
    } catch (err: any) {
      setError('Error al ejecutar los tests')
    } finally {
      setLoading(false)
    }
  }

  const passedTests = testResults.filter(r => r.passed).length
  const totalTests = testResults.length

  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        Tests del Sistema
      </Typography>
      <Typography variant="body1" color="textSecondary" paragraph>
        Ejecuta tests automáticos para verificar funcionalidades
      </Typography>

      <Card sx={{ mb: 3 }}>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            Ejecutar Tests
          </Typography>
          
          <Box display="flex" gap={2} flexWrap="wrap" mb={3}>
            <Button
              variant="contained"
              startIcon={<PlayArrowIcon />}
              onClick={handleRunAllTests}
              disabled={loading}
            >
              Ejecutar Todos los Tests
            </Button>
            <Button
              variant="outlined"
              onClick={handleTestHabitML}
              disabled={loading}
            >
              Test ML Hábitos
            </Button>
            <Button
              variant="outlined"
              onClick={handleTestNotifications}
              disabled={loading}
            >
              Test Notificaciones
            </Button>
            <Button
              variant="outlined"
              onClick={handleTestEnhancedAI}
              disabled={loading}
            >
              Test Enhanced AI
            </Button>
          </Box>

          {loading && (
            <Box display="flex" justifyContent="center" my={3}>
              <CircularProgress />
              <Typography sx={{ ml: 2 }}>Ejecutando tests...</Typography>
            </Box>
          )}

          {error && (
            <Alert severity="error" sx={{ mb: 2 }} onClose={() => setError(null)}>
              {error}
            </Alert>
          )}

          {testResults.length > 0 && (
            <Box sx={{ mt: 3 }}>
              <Box display="flex" alignItems="center" gap={2} mb={2}>
                <Typography variant="h6">
                  Resultados: {passedTests}/{totalTests} tests pasados
                </Typography>
                <Chip
                  label={passedTests === totalTests ? 'Todos Exitosos' : 'Algunos Fallaron'}
                  color={passedTests === totalTests ? 'success' : 'error'}
                />
              </Box>
              <Divider sx={{ mb: 2 }} />
              {testResults.map((result, index) => (
                <Paper
                  key={index}
                  sx={{
                    p: 2,
                    mb: 2,
                    border: result.passed ? '2px solid #4CAF50' : '2px solid #f44336',
                  }}
                >
                  <Box display="flex" alignItems="center" justifyContent="space-between">
                    <Box display="flex" alignItems="center" gap={1}>
                      {result.passed ? (
                        <CheckCircleIcon color="success" />
                      ) : (
                        <ErrorIcon color="error" />
                      )}
                      <Typography variant="subtitle1" fontWeight="bold">
                        {result.name}
                      </Typography>
                    </Box>
                    <Chip
                      label={`${result.duration}ms`}
                      size="small"
                      variant="outlined"
                    />
                  </Box>
                  {result.message && (
                    <Alert severity="error" sx={{ mt: 1 }}>
                      {result.message}
                    </Alert>
                  )}
                  {result.details && (
                    <Box sx={{ mt: 2 }}>
                      <Typography variant="body2" color="textSecondary" gutterBottom>
                        Detalles:
                      </Typography>
                      <Paper
                        sx={{
                          p: 1,
                          backgroundColor: '#f5f5f5',
                          maxHeight: 300,
                          overflow: 'auto',
                        }}
                      >
                        <pre style={{ margin: 0, fontSize: '12px' }}>
                          {JSON.stringify(result.details, null, 2)}
                        </pre>
                      </Paper>
                    </Box>
                  )}
                </Paper>
              ))}
            </Box>
          )}
        </CardContent>
      </Card>

      <Paper sx={{ p: 3 }}>
        <Typography variant="h6" gutterBottom>
          Tests Disponibles
        </Typography>
        <Divider sx={{ mb: 2 }} />
        <Box sx={{ mb: 2 }}>
          <Typography variant="subtitle1" fontWeight="bold">
            Sistema ML de Hábitos
          </Typography>
          <Typography variant="body2" color="textSecondary">
            Verifica análisis de patrones, predicciones, sugerencias de reprogramación
          </Typography>
        </Box>
        <Box sx={{ mb: 2 }}>
          <Typography variant="subtitle1" fontWeight="bold">
            Notificaciones Pre-Evento
          </Typography>
          <Typography variant="body2" color="textSecondary">
            Verifica sistema de notificaciones y diálogos de confirmación
          </Typography>
        </Box>
        <Box>
          <Typography variant="subtitle1" fontWeight="bold">
            Enhanced AI
          </Typography>
          <Typography variant="body2" color="textSecondary">
            Verifica detección inteligente de eventos y clasificación por tipo
          </Typography>
        </Box>
      </Paper>
    </Box>
  )
}
