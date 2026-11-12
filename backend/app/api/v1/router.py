from fastapi import APIRouter
from app.api.v1 import auth, sync, dashboard, stock, ventes, achats, clients, caisse, chifa
from app.api.v1.performance import router as performance_router
from app.api.v1.kpis import router as kpis_router
from app.api.v1.chatbot import router as chatbot_router
from app.api.v1.finance import router as finance_router
from app.api.v1.crm import router as crm_router
from app.api.v1.assistant_achat import router as assistant_achat_router
from app.api.v1.sms import router as sms_router
from app.api.v1.tasks import router as tasks_router
from app.api.v1.grh_presence import router as grh_presence_router
from app.api.v1.grh_employes import router as grh_employes_router
from app.modules.calendrier.router import router as calendrier_router
from app.modules.commandes.router import router as commandes_router

router = APIRouter()
router.include_router(auth.router)
router.include_router(sync.router)
router.include_router(dashboard.router)
router.include_router(stock.router)
router.include_router(ventes.router)
router.include_router(achats.router)
router.include_router(clients.router)
router.include_router(caisse.router)
router.include_router(chifa.router)
router.include_router(performance_router)
router.include_router(kpis_router)
router.include_router(chatbot_router)
router.include_router(finance_router)
router.include_router(crm_router)
router.include_router(assistant_achat_router)
router.include_router(sms_router)
router.include_router(tasks_router)
router.include_router(grh_presence_router)
router.include_router(grh_employes_router)
router.include_router(calendrier_router)
router.include_router(commandes_router)
