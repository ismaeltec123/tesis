import { useEffect, useState } from 'react'
import {
  Box,
  Grid,
  Paper,
  Typography,
  Card,
  CardContent,
  CircularProgress,
  Alert,
} from '@mui/material'
import PeopleIcon from '@mui/icons-material/People'
import EventIcon from '@mui/icons-material/Event'
import CheckCircleIcon from '@mui/icons-material/CheckCircle'
import TrendingUpIcon from '@mui/icons-material/TrendingUp'
import { userAPI, calendarAPI } from '../services/api'

interface Stats {
  totalUsers: number
  totalEvents: number
  completedEvents: number
  avgConsistencyScore: number
}

export default function Dashboard() {
  const [stats, setStats] = useState<Stats | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    loadStats()
  }, [])

  const loadStats = async () => {
    try {
      setLoading(true)
      setError(null)
      
      // Get users
      const users = await userAPI.getAllUsers()
      
      // Get events for all users (this is a simplified version)
      let totalEvents = 0
      let completedEvents = 0
      
      // In a real scenario, you'd fetch this from a dedicated stats endpoint
      // For now, we'll show static data
      setStats({
        totalUsers: users.length,
        totalEvents: totalEvents,
        completedEvents: completedEvents,
        avgConsistencyScore: 0,
      })
    } catch (err: any) {
      setError(err.message || 'Error al cargar estadísticas')
    } finally {
      setLoading(false)
    }
  }

  const StatCard = ({ 
    title, 
    value, 
    icon, 
    color 
  }: { 
    title: string
    value: number | string
    icon: React.ReactNode
    color: string 
  }) => (
    <Card>
      <CardContent>
        <Box display="flex" justifyContent="space-between" alignItems="center">
          <Box>
            <Typography color="textSecondary" gutterBottom>
              {title}
            </Typography>
            <Typography variant="h4" component="div">
              {value}
            </Typography>
          </Box>
          <Box
            sx={{
              backgroundColor: color,
              borderRadius: '50%',
              width: 60,
              height: 60,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              color: 'white',
            }}
          >
            {icon}
          </Box>
        </Box>
      </CardContent>
    </Card>
  )

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="400px">
        <CircularProgress />
      </Box>
    )
  }

  if (error) {
    return (
      <Alert severity="error" onClose={() => setError(null)}>
        {error}
      </Alert>
    )
  }

  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        Dashboard
      </Typography>
      <Typography variant="body1" color="textSecondary" paragraph>
        Resumen general del sistema de calendario
      </Typography>

      <Grid container spacing={3} sx={{ mt: 2 }}>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Total Usuarios"
            value={stats?.totalUsers || 0}
            icon={<PeopleIcon fontSize="large" />}
            color="#00BCD4"
          />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Total Eventos"
            value={stats?.totalEvents || 0}
            icon={<EventIcon fontSize="large" />}
            color="#4CAF50"
          />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Eventos Completados"
            value={stats?.completedEvents || 0}
            icon={<CheckCircleIcon fontSize="large" />}
            color="#FF9800"
          />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Consistencia Promedio"
            value={`${stats?.avgConsistencyScore || 0}%`}
            icon={<TrendingUpIcon fontSize="large" />}
            color="#9C27B0"
          />
        </Grid>
      </Grid>

      <Paper sx={{ mt: 4, p: 3 }}>
        <Typography variant="h6" gutterBottom>
          Información del Sistema
        </Typography>
        <Typography variant="body2" color="textSecondary" paragraph>
          Servidor Backend: http://localhost:8001
        </Typography>
        <Typography variant="body2" color="textSecondary" paragraph>
          Versión: 1.0.0 MVP
        </Typography>
        <Typography variant="body2" color="textSecondary">
          Características Implementadas:
        </Typography>
        <Box component="ul" sx={{ mt: 1 }}>
          <li>Sistema de Estados de Eventos (5 estados)</li>
          <li>Notificaciones Pre-Evento</li>
          <li>Machine Learning para Análisis de Hábitos</li>
          <li>Sugerencias Inteligentes de Reprogramación</li>
          <li>Enhanced AI para Detección de Eventos</li>
          <li>Panel de Administración</li>
        </Box>
      </Paper>
    </Box>
  )
}
